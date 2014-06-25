package TvTropes;

require LWP::Simple;
require LWP::UserAgent;
require HTTP::Request;
require HTTP::Response;
require HTML::LinkExtor;
require CGI;
use strict; 
use Carp;
BEGIN {
	$TvTropes::VERSION = 1.0;
	$Config::modules{'TvTropes'} = 1;
}

use constant( @TvTropes::Namespaces = ("Main","Webcomics","Comicbook","Roleplay","Film","FanFic","Series","ComicStrip",
"Game","TabletopGames","Literature","Music","Anime","Manga","Machinima","Theatre","Webcomic","WebOriginal","WesternAnimation","Disney"));
#use constant (@TvTropes::Namespaces = ("Main"));

sub examine {
	my $input = shift;
	my $channel = shift;
	my $nick = shift;
	
	$input =~ s/\s+$//;
	if ($input =~ /^!tvtropes (.+)/i) {
		$input = $1;
	}elsif ($input =~ /^!trope (.+)/i) {
		$input = $1;
	} elsif ($input =~ /^!TvTropes$/) {
		module_info($channel);
		return 1;
	} else {
		return 0;
		#input not important;
	}

	if ($input =~ /^help (\w*)/i) {
		topic_help($channel,$1);
		#outsiders_topic_help($channel,$1);
	}
	elsif ($input =~ /^help$/i) {
		help($channel);
		#outsiders_help($channel);
	} else {
		link_to($channel,$input)
	}

	return 1; #Because we didn't return false above
}
sub module_info {
	my $where = shift;
	Hermes::IRC_print($where, "TvTropes Functions version $TvTropes::VERSION. Copyright 2011. Created by Yami Kuronue.");
}

sub help {
	my $where = shift;
	topic_help($where, "help");
}

sub topic_help {
	my $where = shift;
	my $what = shift;

	my $response;
	my $found = 0;
	
	open FILE, $Hermes::install_Directory . "/Help/tvtropeshelp.txt";
	my @filearray=<FILE>;
	close(FILE);

	foreach my $line (@filearray) {
		if ($line =~ /^$what\t(.+)/i) {
			$response = $1;
			$found = 1;
		}
	}
	
	if ($found) {
		Hermes::IRC_print($where, $response);
	} else {
		Hermes::IRC_print($where, "Command not found. Help Commands for commands");
	}
}



sub link_to {
	my $channel = shift;
	my $thing = shift;


	if ($thing =~ /\/..\//) {
		Hermes::log($channel,"Error for " . $thing . ": contained invalid sequence");
		Hermes::IRC_print($channel,"R...Red? Is that y-you? I... I mean... *cough* Invalid link.");
		return;
	}
	$thing = ucfirst($thing);
	$thing = CGI::escape($thing) or croak("ERROR");

			
	my $baseURL = "http://tvtropes.org/pmwiki/pmwiki.php/";

	$baseURL =~ s/\s/_/g;
	#Create browser object
	my $browser = LWP::UserAgent->new();
		
	$browser->timeout(10);

	
	#Download URL
	my $found = 0;
	foreach my $namespace (@TvTropes::Namespaces) {
		my $URL = $baseURL . $namespace . "/" . $thing;
		my $request = HTTP::Request->new(GET => $URL);
		my $response = $browser->request($request);
		if ($response->is_error()) {
			Hermes::log($channel,"Error for " . $URL . ": " .$response->status_line);
			Hermes::IRC_print($channel,"Invalid link.");
			return;
		}
		else {
			my $raw = $response->content();
		
			if ($raw =~ /This wiki is a catalog of the tricks of the trade for writing fiction./) {
				Hermes::IRC_print($channel,$thing . " appears to lead to the home page: http://tvtropes.org/pmwiki/pmwiki.php/Main/HomePage");
				Hermes::log("Found the home page.");
				return;
			}
			if (!($raw =~ /Click the edit button to start this new page/i)) {
				Hermes::IRC_print($channel,$thing . ": " . $URL);
				Hermes::log($thing . ": " . $URL);
				$found++;
			}
		}
	}

	if ($found == 0) {
		Hermes::IRC_print($channel,"Sorry, " . $thing . " appears to be a redlink.");
		Hermes::log("Sorry, I don't know what trope " . $thing . " is.");
	}
	return;
}
