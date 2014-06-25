#Copyright (C) 2011  Bayley Green (hereafter known as Yami Kuronue)

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl
package Logios;
$VERSION = 3.6;

use FindBin qw($Bin);
push @INC,$Bin;
push @INC ,"/usr/local/lib/perl5/site_perl/5.10.1/";

require("Logios_Config.pm");
$install_Directory = $Config::install_Directory;
push @INC,$install_Directory; #Fix for running from rc.local

use warnings;
#use strict;
use Safe;
use POE;
use POE::Component::IRC;
use Module::Reload;
use Math::Expression::Evaluator;
use File::Spec;

my $quit = 0; #By default, we are not attempting to quit the bot
our %Channels; #Tracks a list of channels. This will be populated at connection time from the config

#Config file
my $botnick = $Config::botnick;
our $quitpassword = $Config::password;
my $server = $Config::server;
my $port = $Config::port;
#my @CHANNEL = @Config::channels;


#Load modules
foreach $modfile (@Config::modulefiles) {
	require($modfile);
}


# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
  inline_states => {
	_start     => \&bot_start,
	irc_001    => \&on_connect,
	irc_public => \&on_public,
	irc_msg	   => \&on_msg,
	irc_disconnected => \&on_disconnect,
	irc_error        => \&on_disconnect,
	irc_socketerr    => \&on_disconnect,
	irc_ctcp_action => \&on_me,

  },
);


# Run the bot until it is done.
$poe_kernel->run();
exit 0;


######FUNCTIONS#########

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
  $irc->yield(register => "all");
  $irc->yield(
    connect => {
      Nick     => $botnick,
      Username => 'LogiosBot ver ' . $VERSION,
      Ircname  => 'LogiosBot ver ' . $VERSION,
      Server   => $server,
      Port     => $port,
    }
    );
    
}

###### IRC REACTIONS ########
# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
	foreach $channel (@Config::channels) {
		$Channels{$channel} = Channel::new($channel);
		$irc->yield(join => $channel);
		#Reaction::addchan($channel);  #No longer needed
	}
	Logios::log("Bot started!");
}

sub on_disconnect {
	if ($quit == 1) {
		exit;
	} else {
		$irc->yield(
		 	connect => {
      				Nick     => $botnick,
   				Username => 'LogiosBot ver ' . $VERSION,
				Ircname  => 'LogiosBot ver ' . $VERSION,
				Server   => $server,
				Port     => $port,
			}
  		);
	}
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
	my ($kernel, $who, $where, $text) = @_[KERNEL, ARG0, ARG1, ARG2];
	my $nick    = (split /!/, $who)[0];
	my $channel = $where->[0];
	my $ts      = scalar localtime;
	my $type = "public";
	

	#Filtration
	my %filter = map { $_ => 1 } @Config::filterList;
	if ($Config::filterMode eq "whitelist") {
	    if(!exists($filter{$nick})) {
	      return;
	    }
	}

	if ($Config::filterMode eq "blacklist") {
	    if(exists($filter{$nick})) {
	      return;
	    }
	}

      
	#core functions
	examine($text,$channel,$nick);

	#plugin functions
	foreach $mod (sort keys %Config::modules) {
		$evalstring = $mod . "::examine(" . '$text,$channel,$nick,$type)';
		last if eval $evalstring;
		#eval $evalstring;
	}
}

sub on_me {
	my ($kernel, $who, $where, $text) = @_[KERNEL, ARG0, ARG1, ARG2];
	my $nick    = (split /!/, $who)[0];
	my $channel = $where->[0];
	my $ts      = scalar localtime;
	my $type = "action";
	
	#core functions
	examine($text,$channel,$nick);

	#plugin functions
	foreach $mod (sort keys %Config::modules) {
		$evalstring = $mod . "::examine(" . '$text,$channel,$nick,$type)';
		last if eval $evalstring;
	}
}

sub on_msg {
	my ($kernel, $who, $where, $text) = @_[KERNEL, ARG0, ARG1, ARG2];
	my $nick    = (split /!/, $who)[0];
	my $channel = $where->[0];
	my $ts      = scalar localtime;
	my $type = "privmsg";

	#core functions
	examine($text,$nick,$nick);

	#plugin functions
	#foreach $module (@Config::modules) {
	foreach $mod (sort keys %Config::modules) {
		$evalstring = $mod . "::examine(" . '$text,$nick,$nick,$type)';
		last if eval $evalstring;
	}
}

########## Bot Routines ############
#The real meat of Logios: its functional subroutines
sub examine {
	my $input = shift;
	my $channel = shift;
	my $nick = shift;
	
	#IRC commands
	if ($input =~ /^\!(\w+)\s(.+)/i) {  #"!word word
		$word2 = $2;
		if ($1 =~ /^join$/i) {
			IRC_join($word2);
			#$irc->yield(join => $word2);
		} elsif ($1 =~ /^part$/i || $1 =~ /^leave$/i) {
			IRC_part($word2);
			#$irc->yield(part => $word2);
		} elsif ($1 =~ /^repeat$/i || $1 =~ /^echo$/i) {
			IRC_print($channel, $word2);
		} 
		elsif ($1 =~ /^calc$/i) {
			calculator($channel,$word2);
		}
		elsif ($1 =~ /^help$/i) {
			general_help($channel,$word2);
		} 
	} elsif ($input =~ /^\!(\w+)/i){ 
		if ($1 =~ /^help$/i) {
			general_help($channel,"help");
		} 
		elsif ($1 =~ /^part$/i || $1 =~ /^leave$/i) {
			$irc->yield(part => $channel);
		}
		elsif ($1 =~ /^modules$/i) {
			my $output = "Loaded modules: ";
			foreach $mod (sort keys %Config::modules) {
				$output .=  " " . $mod;
			}
			IRC_print($channel,$output);
		} elsif ($1 =~ /^Logios$/ || $1 =~ /^LogiosBot$/) {
			module_info($channel);
		}
	}

	#PM only commants
	if ($nick eq $channel && $input =~ /^\!(\w+)\s(.+)/i) {
		my $term2 = $2;
		if ($1 eq "quit" && $term2 eq $Logios::quitpassword) {
			# Send the QUIT command to the IRC
			Logios::log("Instructed to quit by " . $nick);
			$irc->yield(quit => "Instructed to quit"); 
			$quit++;
			#exit(1);
		}
		elsif ($1 =~ /^reload$/i ) {
			if ($term2 eq $Logios::quitpassword) {
				#Backup module list
				%modulebackup = %Config::modules;
				Module::Reload->check;
				#Config::Refresh();
				IRC_print($nick,"Modules reloaded");
				Logios::log("Modules reloaded by " . $nick);
			}
		}
		elsif ($1 =~ /^modules$/i ) {
			if ($term2 eq $Logios::quitpassword) {
				Config::list_modules($nick);
			}
		}
	} 
}

#Basic IRC commands: Join, part, send text
sub IRC_join {
	my $where = shift;
	$Channels{$where} = Channel::new($where);
	$irc->yield(join => $where);
	Logios::log("Joined " . $where);
}

sub IRC_part {
	my $where = shift;
	delete $Channels{$where};
	$irc->yield(part => $where);
	Logios::log("Parted " . $where);
}

#General help, from helpfile
sub general_help {
	my $where = shift;
	my $what = shift;

	my $response;
	my $found = 0;
	
	($volume, $directories,$file) = File::Spec->splitpath( $install_Directory );
	@dirs = File::Spec->splitdir( $directories );
	push(@dirs,"Help");
	$helppath = File::Spec->catfile( @dirs, "generalhelp.txt" );
	open FILE, $helppath;
	
	#check if file is open
	if (tell FILE == -1) {
	    IRC_print($where, "Error getting help file. Is my config correct?");
	    return;
	}
	@filearray=<FILE>;


	

	foreach $line (@filearray) {
		if ($line =~ /^$what\t(.+)/i) {
			$response = $1;
			$found = 1;
		}
	}
	close(FILE);

	if ($found) {
		IRC_print($where, $response);
	} else {
		IRC_print($where, "Command not found. Help Commands for commands, or Help Help for help about help.");
	}
}		

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "LogiosBot version $VERSION. Copyright 2011, released under GLPv3. Created by Yami Kuronue.");
}

#Simple calculator
#Now with more complex expressions
sub calculator {
	my $where = shift;
	my $expression = shift;
	eval {
		my $answer = Math::Expression::Evaluator->new->parse($expression)->val;
		$result = "Calculator: " . $expression . " = " . $answer;
		IRC_print($where, $result);
	};
	if ($@) {
		if ($@ =~ /division by zero/) {
			$result = "Please do not divide by zero.";
		} else {
			$result = "Invalid expression.";
		}
		IRC_print($where, $result);
	}
}
#########OUTPUT#########
#The most-referenced sub, this prints to a channel or nick ($where) the text, with cutting for lengthy paragraphs
sub IRC_print {
	my $where = shift;
	my $text = shift;
	#$text =~ s/\\([^\\])/$1/;   #Removed for performance issues
	 
	if (!defined($irc)) {
		use Carp;
		confess "We've had an error here in IRC_print";
	}
	if (length($text) > 400) {
		IRC_print($where,substr($text,0,399));
		IRC_print($where,substr($text,399,length($text)-399));
	} else {
		$irc->yield(privmsg => $where, $text);
	}
}


#Log normal operations
sub log {
	my $string = shift;
	open LOG, ">>" .$Config::logfile;
	my ($second, $minute, $hour) = localtime();
	my $timestamp = sprintf("%.2d:%.2d:%.2d", $hour, $minute,$second);
	print LOG $timestamp . ": " . $string . "\r\n";
	close LOG;
}

#Log errors
sub log_error {
	my $string = shift;
	open LOG, ">>" . $Config::errorfile;
	my ($second, $minute, $hour) = localtime();
	my $timestamp = sprintf("%.2d:%.2d:%.2d", $hour, $minute,$second);
	print LOG $timestamp . ": " . $string . "\r\n";
	close LOG;
}


#--------------------------------------------
#Channel object
package Channel;

sub new {
	my $name = shift;
	my $channel = {
		"name" 			=>  $name, #name of chan, aka location
		"monitor" 		=> 'on',   #Do we respond to it? Not all modules use this yet
		"reactions" 	=>  'on',  #Do we react to non-commands? Used by personality modules
	};
	bless $channel, 'Channel';
	return $channel;
}

sub name {
	my $channel = shift;
	return $channel->{"name"};
}

sub monitoring {
	my $channel = shift;
	@_ ? $channel->{"monitor"} = shift   #If there is a second argument, change the monitoring to that argument
		: return $channel->{"monitor"};			#otherwise just return the monitoring value
}

sub reacting {
	my $channel = shift;
	@_ ? $channel->{"reactions"} = shift   #If there is a second argument, change the reactions to that argument
		: return $channel->{"reactions"};			#otherwise just return the value
}
