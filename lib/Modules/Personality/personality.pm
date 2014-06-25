package Reaction;
$VERSION = 1.5;

#%settings;
=pod

=head1 NAME
Reactions: Sample personality quirks for LogiosBot

=head1 DESCRIPTION
Personality quirks for LogiosBot. I suggest customizing this to fit your group!

=head1 USEAGE
To disable reactions for a channel, use !reactions off. 
to re-enable them, use !reactions on
This is channel specific. 

=head1 Author
Yamikuronue - yamikuronue at gmail.com

=head1 LICENSE
gpl 3.0
=cut

BEGIN {
	$version = 1.5;
	$Config::modules{'Reaction'} = 1;
}

#The all-important Examine function, called whenever text is issued
sub examine {
	my $text = shift;
	my $channel = shift;
	my $nick = shift;
	my $type = shift;
	
	$text =~ s/\s+$//;

	if ($text =~ /are you pondering what (.+) pondering/i) {
		ponder($channel, $nick);
	}
	if ($text =~ /^!fortune/i) {
		fortune($channel, $nick);
	}
	if ($text =~ / cake /i) {
		cake($channel);
	}
	if ($text =~ /do you like waffles/i) {
		waffles($channel);
	}
    if ($text =~ /fork(.)*while(.)*fork/i) {
        fork_response($channel);
    }
	if ($text =~ /^!reactions (\w+)/i) {
		set_reactions($channel,$1);
	}
	
	if ($text =~ /^!Reaction$/i) {
		module_info($channel);
		return 1;
	}

	return 0;
}

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "Reactions for Logios version $VERSION. Copyright 2011. Created by Yami Kuronue.");
}

#Configuration functions which enable or disable reactions
sub addchan {
	my $chan = shift;
	$Logios::Channels{$chan}->reacting('on');
	#$settings{$chan} = 'on';
}

sub enable_reactions {
	my $chan = shift;
	$Logios::Channels{$chan}->reacting('on');
	#$settings{$chan} = 'on';
}

sub disable_reactions {
	my $chan = shift;
	$Logios::Channels{$chan}->reacting('off');
	#$settings{$chan} = 'off';
}

sub set_reactions {
	my $chan = shift;
	my $setting = shift;
	#$settings{$chan} = $setting;
	if ($setting eq 'on' || $setting eq 'off') {
		$Logios::Channels{$chan}->reacting($setting);
		Logios::IRC_print($chan, "Reactions turned " . $setting);
	} else {
		Logios::IRC_print($chan, "Invalid setting '$setting': use 'on' or 'off'");
	}
}


#-------------------
#The actual reactions themselves

#Responds to "Are you pondering what I'm pondering?" with Pinky and the Brain quotes
sub ponder {
	my $where = shift;
	my $nick = shift;

	#if ($settings{$where} eq "off") {
	if ($Logios::Channels{$where}->reacting() eq 'off') {
		return;
	}

	my $linenum = rand(74) + 1;
	
	$data_file= $Config::install_Directory . "/pinky.txt";
	open(DAT, $data_file) || die("Could not open file!");
	@responses=<DAT>;
	close(DAT); 	

	Logios::IRC_print($where, "I think so, " . $nick . ", " . $responses[$linenum]);
	return;
}

#Responds to "!fortune" with a fortune cookie
sub fortune {
	my $where = shift;
	my $nick = shift;

	#if ($settings{$where} eq "off") {
	if ($Logios::Channels{$where}->reacting() eq 'off') {
		return;
	}
	
	$data_file= $Config::install_Directory . "/fortunes.txt";
	open(DAT, $data_file) || die("Could not open file!");
	@responses=<DAT>;
	close(DAT); 	
	
	my $linenum = rand(scalar @responses) + 1;

	Logios::IRC_print($where, $nick . ": " . $responses[$linenum]);
	return;
}

#Responds to the mention of Cake with "The cake is a lie". 
sub cake {
	my $where = shift;

	#if ($settings{$where} eq "off") {
	if ($Logios::Channels{$where}->reacting() eq 'off') {
		return;
	}
	Logios::IRC_print($where, "THE CAKE IS A LIE!");
	return;
}

sub waffles {
	my $where = shift;

	#if ($settings{$where} eq "off") {
	if ($Logios::Channels{$where}->reacting() eq 'off') {
		return;
	}
	Logios::IRC_print($where, "Yeah we like waffles!");
	return;
}

1;
