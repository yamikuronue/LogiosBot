package CAH;
$VERSION = 1.0;

=pod

=head1 NAME
Cards Against Humanity: A game for IRC bot LogiosBot

=head1 DESCRIPTION
A module for LogiosBot that more or less plays Cards Against Humanity over IRC. 

=head1 USEAGE
To start a game: !cah start
To join a game in progress: !cah join 
To quit a game you have joined: !cah quit
To see your hand: !cah hand. This will show your hand via PM. 
To play a card (non-judge): !cah play Cardname
To select a card (judge): !cah pick Cardname
To end the game: !cah end. 

=head1 Gameplay
The game requires at least three players, each of whom is dealt a hand of noun cards that is kept secret. 
Each round, one player will be announced as the judge. An adjective card will be drawn for the judge and played onto the table. 
Each non-judge player must then play a noun card that they feel matches the adjective card best. 
When all non-judge players have played their cards, they will be presented anonymously to the judge. The judge must select the best fit from the card presented. 

=head1 Author
Yamikuronue - yamikuronue at gmail.com
 


=cut

#%settings;

BEGIN {
	$Config::modules{'Apples'} = 1;
	$filepath = $Config::CahFilePath;

	# read files
	$nouncount = 0;
	open (NOUNS, $filepath . "/White.txt") or die "Could not read noun file at " . $filepath . "/nouns.txt";
	while ($line = <NOUNS>) {
		($noun,$desc) = split(/ - /,$line);
		push(@nouns,$noun);
		$red{$noun} = $desc;	
		$nouncount++;
	}
	close (NOUNS);

	$adjectivecount = 0;
	open (ADJECTIVES, $filepath . "/Black.txt") or die "Could not read adjective file";
	while ($line = <ADJECTIVES>) {
		($adj,$desc) = split(/ - /,$line);
		push(@adjectives,$adj);
		$green{$adj} = $desc;		
		$adjectivecount++;
	}
	close (ADJECTIVES);


	$channel = 0;
}

our @nouns, @adjectives, %green, %red,%games,$nouncount, $adjectivecount, %dealt;

#The all-important Examine function, called whenever text is issued
sub examine {
	my $text = shift;
	my $where = shift;
	my $who = shift;
	my $type = shift;

	$text =~ s/\s+$//;
	if ($text =~ /^!cah (.+)/i) {
		$input = $1;
	} elsif ($text =~ /^!cah (.+)/i) {
		$input = $1;
	} elsif ($text =~ /^!cah$/i) {
		module_info($where);
		return 1;
	} else {
		return 0;
	}

	if ($input =~ /^help (\w*)/i) {
		topic_help($where,$1);
	} elsif ($input =~ /help/i) {
		help($where);
	} elsif ($input =~ /^start/i) {
		start_game($where);
	} elsif ($input =~ /^end/i) {
		end_game($where);
	} elsif ($input =~ /^players/i) {
		list_players($where);
	} elsif ($input =~ /^join/i) {
		add_player($where,$who);
	} elsif ($input =~ /^quit/i) {
		remove_player($where,$who);
	} elsif ($input =~ /^play ([\w\s]+)/i) {
		play_card($where,$who,$1);
	} elsif ($input =~ /^pick ([\w\s]+)/i) {
		choose_card($where,$who,$1);
	} elsif ($input =~ /^score/i) {
		scores($where);
	} elsif ($input =~ /^hand/i) {
		show_hand($who,$where);
	} elsif ($input =~ /^debug_dump/i) {
		debug_dump($where);
	} else {
		return 0;
	}

	return 1;
}

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "Apples Game version $VERSION. Created by Yami Kuronue.");
}

sub debug_dump {
	my $where = shift;
	$game = $games{$where};

	use Data::Dumper;
	$d = Data::Dumper->new([$game], [qw(game)]);
			#Logios::IRC_print($where, $d->Dump);
	print $d->Dump;
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
	
	($volume, $directories,$file) = File::Spec->splitpath( $install_Directory );
	@dirs = File::Spec->splitdir( $directories );
	push(@dirs,"Help");
	$helppath = File::Spec->catfile( @dirs, "CAHhelp.txt" );
	open FILE, $helppath;
	
	#check if file is open
	if (tell FILE == -1) {
	    IRC_print($where, "Error getting help file. Is my config correct?");
	    return;
	}
	@filearray=<FILE>;

	close(FILE);

	foreach $line (@filearray) {
		if ($line =~ /^$what\t(.+)/i) {
			$response = $1;
			$found = 1;
		}
	}
	
	if ($found) {
		Logios::IRC_print($where, $response);
	} else {
		Logios::IRC_print($where, "Command not found. Help Commands for commands");
	}
}

sub start_game {
	my $where = shift;
	
	if (defined($games{$where})) {
		Logios::IRC_print($where,"Game already in progress");
		return;
	}
	
	Logios::IRC_print($where,"Welcome to Cards Against Humanity! I will be using this channel for the game.");
	Logios::IRC_print($where,"To join the game, type !cah join at any time.");
	Logios::IRC_print($where,"When at least three people have joined, the game will begin properly.");
	$games{$where} = Game::new($where);
	
}

sub end_game {
	my $where = shift;

	if (defined($games{$where})) {
		Logios::IRC_print($where,"That's game over, folks!");
		$games{$where}->show_scores;
		undef $games{$where};
	} else {
		Logios::IRC_print($where,"You have to start before you can end!");
	}
	
	
}

sub add_player {
	my $where = shift;
	my $who = shift;

	if (!defined($games{$where})) {
		Logios::IRC_print($where,"No game is active in this room!");
	} else {
		eval {
			if($games{$where}->add_player($who)) {
				show_hand($who,$where);
				Logios::IRC_print($where,"Added " . $who);
			}
		};
		if ($@) {
			Logios::IRC_print($where,"Something went wrong: " . $@);
			use Carp qw(cluck);
			cluck "Stack trace";

			print "Something went wrong: " . $@;
		}
	}
}

sub remove_player {
	my $where = shift;
	my $who = shift;

	if (!defined($games{$where})) {
		Logios::IRC_print($where,"No game is active in this room!");
	} else {
		eval {
			$games{$where}->remove_player($who)
		};
		if ($@) {
			Logios::IRC_print($where,"Something went wrong: " . $@);
			use Carp qw(cluck);
			cluck "Stack trace";

			print "Something went wrong: " . $@;
		}
	}
}

sub list_players {
	my $where = shift;
	eval {
		$game = $games{$where};
		$output = "Now playing: ";
		foreach $player ($game->players()) {
			$output .= $player->nick;
			Logios::IRC_print($where,"A challenger approaches");
		}
		Logios::IRC_print($where, $output);
	};
	if ($@) {
			Logios::IRC_print($where,"Something went wrong: " . $@);
			use Carp qw(cluck);
			cluck "Stack trace";

			print "Something went wrong: " . $@;
	}
}


sub show_hand {
	my $who = shift;
	my $where = shift;

	
	
	eval {
			$game = $games{$where};
			%players = \($game->players());
			$player = $players{$who};
			#make sure that's valid later
			#@hand = $game->{_players}{$who}->hand;

			$game->{_players}{$who}->show_hand;
			#use Data::Dumper;
			#$d = Data::Dumper->new([\@hand], [qw(hand)]);
			#Logios::IRC_print($where, $d->Dump);
			#print $d->Dump;

			#for ($i = 0; $i < 7; $i++) {
			#%card = $hand[0][i];
			#Logios::IRC_print($who, $card{"name"} . ": " . $card{"desc"});
			#}
		};
		if ($@) {
			Logios::IRC_print($where,"Something went wrong: " . $@);
			print "Something went wrong: " . $@;

			
			use Carp qw(cluck);
			cluck "Stack trace";
		}
}

sub play_card {
	my $where = shift;
	my $who = shift;
	my $what = shift;

	my $game = $games{$where};

	if (defined($game->{_players}{$who})) {
		$game->{_players}{$who}->play_card($game,$what);
	}
}

sub choose_card {
	my $where = shift;
	my $who = shift;
	my $what = shift;

	my $game = $games{$where};
	if (defined($game)) {
		if ($who eq $game->{_judge}) {
			$game->choose_card($what);
		} else {
			Logios::IRC_print($where,"You are not the judge.");
		}
	}

}

sub scores {
	my $where = shift;
	my $game = $games{$where};
	if (defined($game)) {
		$game->show_scores;
	}
}
	
1;
		

#---------------
package Player;
sub new {
	my $pkg = shift;
	my $nick = shift;
	my $game = shift;
	
	my $self = {};
	$self->{_nick} = $nick;
	$self->{_hand} = $game->deal_hand($nick,$game);
	$self->{_played} = 0;  #Have I played this turn
	$self->{_score} = 0;   #Current score
	bless $self;


	return $self;
}

sub nick {
	my $self = shift;
	my $nick = shift;
	if (defined($nick)) {
		$self->{_nick} = $nick;	
	}
	return $self->{_nick};
}

sub hand {
	my $self = shift;
	my @hand = shift;
	if (defined(@hand)) {
		$self->{_hand} = @hand;	
	}
	return $self->{_hand};
}

sub show_hand {
	my $self = shift;
	my $where = shift;

	my @hand = $self->{_hand};

	for ($i = 0; $i < 7; $i++) {
		$card = $hand[0][$i];
		Logios::IRC_print($self->{_nick}, "Card " . $i . " : " . $card->{"name"} );
	}
}

sub hand_short {
	my $self = shift;
	my $where = shift;
	my $out = "";

	my @hand = $self->{_hand};

	for ($i = 0; $i < 7; $i++) {
		$card = $hand[0][$i];
		$out .= $i . ": " . $card->{"name"} . "; ";
	}
	Logios::IRC_print($self->{_nick}, "Your hand: " . $out);
}

sub play_card {
	my $self = shift;
	my $game = shift;
	#my $cardname = shift;
	my $cardnum = shift;
	my $found = 0;

	if ($self->{_played} == 1) {
		Logios::IRC_print($self->{_nick}, "You have already played this turn!");
		return;
	}

	if ($game->{_judge} eq $self->{_nick}) {
		Logios::IRC_print($self->{_nick}, "You are the judge!");
		return;
	}

	if ($cardnum >= 7 || $cardnum < 0) {
		Logios::IRC_print($self->{_nick}, "Invalid card.");
		return;
	}

	my @hand = $self->{_hand};

	$card = $hand[0][$cardnum];
	$game->add_table($card->{"name"},$self->{_nick});
	$self->{_played} = 1;
	Logios::IRC_print($self->{_nick}, "You played " . $card->{"name"});

	##Deal new card
	$rand = int(rand($Apples::nouncount));
	while (exists($game->{_dealt}{$rand})) {
			$rand = int(rand($Apples::nouncount));
	}
	$hand[0][$cardnum] = {
			"name" => $Apples::nouns[$rand]
	};
	Logios::IRC_print($self->{_nick}, "-------------");
	#Logios::IRC_print($self->{_nick}, "Your hand is now:");
	Logios::IRC_print($self->{_nick}, "You just drew:");
	Logios::IRC_print($self->{_nick}, "Card " . $cardnum . " : " . $Apples::nouns[$rand];
	$self->hand_short;
}

sub new_turn {
	my $self = shift;
	$self->{_played} = 0;
}
#----- 
package Game;
sub new {
	my $pkg, $chan = shift;
	my $self = {};
	$self->{_channel} = $chan;
	$self->{_players} = {};
	$self->{_judge} = "undef";
	$self->{_status} = "Initializing";
	$self->{_num_players}	= 0;
	$self->{_dealt}	= {};
	$self->{_table} = {};
	bless $self;

	return $self;
}

#accessor methods
sub channel {
	my $self = shift;
	my $chan = shift;
	if (defined($chan)) {
		$self->{_channel} = $chan;	
	}
	return $self->{_channel};
}
sub players {
	my $self = shift;
	return \$self->{_players};
}
sub judge {
	my $self = shift;
	my $newjudge = shift;
	if (defined($newjudge)) {
		$self->{_judge} = $newjudge;	
	}
	return $self->{_judge};
}
sub Status {
	return $self->{_status};
}
sub Num_players {
	my $self = shift;
	my $num = shift;
	if (defined($num)) {
		$self->{_num_players} = $num;	
	}
	return $self->{_num_players};
}
sub Dealt {
	my $self = shift;
	return \$self->{_dealt};
}

sub remove_player {
	my $self = shift;
	my $who = shift;
	my $where = $self->{_channel};

	if (defined($self->{_players}{$who})) {
		delete($self->{_players}{$who});
		$self->Num_players($self->Num_players-1);
		Logios::IRC_print($where, $who . " is no longer playing.");
	}

}
sub add_player {
	my $self = shift;
	my $who = shift;

	if (defined($self->{_players}{$who})) {
		$where = $self->{_channel};
		Logios::IRC_print($where, "Cannot join twice, " . $who);
		return 0;
	}
	my $player = new Player($who,$self);
	$self->{_players}{$who} = $player;

	if (($self->Num_players >= 2 && $self->{_status} eq "Initializing")) {
		$judgenick = $self->pick_judge();
		$self->deal_judge($judgenick);
	}

	$self->Num_players($self->Num_players+1);

	
	print "Added player \n";
	return 1;
}

sub pick_judge {
	my $self = shift;

	my @players;
	foreach $player (keys %{$self->{_players}}) {
		push(@players,$player);
	}

	$self->{_status} = "Ready";
	@players = sort(@players);

	$currjudge = $self->{_judge};
	$newjudge = 0;

	$length = scalar(@players);
	if ($currjudge eq "undef") {
		print "Judge undef \n";
		$newjudge = $players[0];
	} elsif ($currjudge eq $players[$length-1]) {
		$newjudge = $players[0];
		print "Judge wrapping \n";
	} else {
		for ($i = 0; $i < $length; $i++) {
			if ($players[$i] eq $currjudge) {
				$newjudge = $players[$i+1];
				print "Judge at position" . $i ." \n";
				break;
			}
		}
	}

	#if (!($currjudge == scalar(@players))) {
	#	$newjudge = $currjudge + 1;
	#}

	$self->{_judge} = $newjudge;

	$where = $self->{_channel};
	Logios::IRC_print($where, $newjudge . " is now the judge");
	

	return $newjudge;

}

sub deal_hand {
	my $pkg = shift;
	my $who = shift;
	my $game = shift;
	my @hand;
	
	if (scalar($game->{_dealt}) > $Apples::nouncount-7) {
		$game->shuffle;
	}
	for ($i = 0; $i < 7; $i++) {
		$card = int(rand($Apples::nouncount));
		#check collisions
		while (exists($game->{_dealt}{$card})) {
			$card = int(rand($Apples::nouncount));
		}	
		push (@hand, {
				"name" => ,
				"desc" => $Apples::red{$Apples::nouns[$card]},
			}	
		);
		$game->{_dealt}{$card} = 1;	
	}
	return \@hand;
}

sub shuffle {
	my $self = shift;
	my $where = $self->{_channel};
	Logios::IRC_print($where, "Shuffling, please wait.");
	
	foreach $dealtcard (keys %{$self->{_dealt}}) {
		my $found = 0;
		foreach $player (keys %{$self->{_players}}) {
			my @hand = $self->{_players}{$player}->{_hand};
			for ($i = 0; $i < 7; $i++) {
				$card = $hand[0][$i];
				if ($card->{"name"} eq 	$Apples::nouns[$self->{_dealt}{$dealtcard}]) {
					$found = 1;
				}
			}
			if (!$found) {
				delete($self->{_dealt}{$dealtcard});
			}
		}
	}
		Logios::IRC_print($where, "Shuffling complete");
}

sub deal_judge {
	my $self = shift;
	my $judge = shift;

	$card = int(rand($Apples::adjectivecount));

	$where = $self->{_channel};
	Logios::IRC_print($where, $judge .  " just drew \x02" . $Apples::adjectives[$card] . "\x02: " .  $Apples::green{$Apples::adjectives[$card]});
}

sub add_table {
	my $self = shift;
	my $card = shift;
	my $nick = shift;

	$self->{_table}{$card} = $nick;
	$numcards = scalar keys %{$self->{_table}};

	if ($numcards ==$self->{_num_players}-1) {
		$self->begin_judging;
	}			
}

sub begin_judging {
	my $self = shift;

	$where = $self->{_channel};
	Logios::IRC_print($where, $self->{_judge} . ", it is time to judge. The following cards have been played:");
	foreach $card (keys %{$self->{_table}}) {
		Logios::IRC_print($where,"   " . $card);
	}

	$self->{_status} = "Judging";
}

sub choose_card {
	my $self = shift;
	my $card = shift;
	my $where = $self->{_channel};

	if (defined($self->{_table}{$card})) {
		$winner = $self->{_table}{$card};
		Logios::IRC_print($where,$winner . "'s card was chosen!");
		$self->{_players}{$winner}->{_score}++;
		$self->show_scores;
		$self->end_turn;
	} else {
		Logios::IRC_print($where,"Invalid card.");
		return;
	}
}

sub show_scores {
	my $self = shift;
	my $where = $self->{_channel};

	Logios::IRC_print($where,"Scores:");

	foreach $player (sort {$self->{_players}{$b}->{_score} <=> $self->{_players}{$a}->{_score} } (keys %{$self->{_players}})) {
		Logios::IRC_print($where,"   " . $player . ": " .$self->{_players}{$player}->{_score});
	}
}


sub end_turn {
	my $self = shift;
	foreach $player (keys %{$self->{_players}}) {
		$self->{_players}{$player}->new_turn;
	}

	$self->{_table} = {};
	$self->{_status} = "Ready";
	$judgenick = $self->pick_judge;
	$self->deal_judge($judgenick);

}

