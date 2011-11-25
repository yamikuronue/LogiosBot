package Reaction;
$VERSION = 1.5;

#%settings;

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
	Hermes::IRC_print($where, "Reactions for Hermes version $VERSION. Copyright 2011. Created by Yami Kuronue.");
}

#Configuration functions which enable or disable reactions
sub addchan {
	my $chan = shift;
	$Hermes::Channels{$chan}->reacting('on');
	#$settings{$chan} = 'on';
}

sub enable_reactions {
	my $chan = shift;
	$Hermes::Channels{$chan}->reacting('on');
	#$settings{$chan} = 'on';
}

sub disable_reactions {
	my $chan = shift;
	$Hermes::Channels{$chan}->reacting('off');
	#$settings{$chan} = 'off';
}

sub set_reactions {
	my $chan = shift;
	my $setting = shift;
	#$settings{$chan} = $setting;
	if ($setting eq 'on' || $setting eq 'off') {
		$Hermes::Channels{$chan}->reacting($setting);
		Hermes::IRC_print($chan, "Reactions turned " . $setting);
	} else {
		Hermes::IRC_print($chan, "Invalid setting '$setting': use 'on' or 'off'");
	}
}


#-------------------
#The actual reactions themselves

sub ponder {
	my $where = shift;
	my $nick = shift;

	#if ($settings{$where} eq "off") {
	if ($Hermes::Channels{$where}->reacting() eq 'off') {
		return;
	}

	my $linenum = rand(74) + 1;
	
	$data_file= $Config::install_Directory . "/pinky.txt";
	open(DAT, $data_file) || die("Could not open file!");
	@responses=<DAT>;
	close(DAT); 	

	Hermes::IRC_print($where, "I think so, " . $nick . ", " . $responses[$linenum]);
	return;
}

sub fortune {
	my $where = shift;
	my $nick = shift;

	#if ($settings{$where} eq "off") {
	if ($Hermes::Channels{$where}->reacting() eq 'off') {
		return;
	}
	
	$data_file= $Config::install_Directory . "/fortunes.txt";
	open(DAT, $data_file) || die("Could not open file!");
	@responses=<DAT>;
	close(DAT); 	
	
	my $linenum = rand(scalar @responses) + 1;

	Hermes::IRC_print($where, $nick . ": " . $responses[$linenum]);
	return;
}

sub cake {
	my $where = shift;

	#if ($settings{$where} eq "off") {
	if ($Hermes::Channels{$where}->reacting() eq 'off') {
		return;
	}
	Hermes::IRC_print($where, "THE CAKE IS A LIE!");
	return;
}

sub waffles {
	my $where = shift;

	#if ($settings{$where} eq "off") {
	if ($Hermes::Channels{$where}->reacting() eq 'off') {
		return;
	}
	Hermes::IRC_print($where, "Yeah we like waffles!");
	return;
}

sub fork_response {
        my $where = shift;

        #if ($settings{$where} eq "off") {
        if ($Hermes::Channels{$where}->reacting() eq 'off') {
                return;
        }
        Hermes::IRC_print($where, "NOOOO! *runs away in horror*");
        $irc->yield(part => $where);
        sleep(3);
        $irc->yield(join => $where);
        Hermes::IRC_print($where, "...is it safe yet?");
        return;
}

1;
