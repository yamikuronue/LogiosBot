package LogiosCards;
use File::Slurp;

=pod

=head1 NAME
LogiosCards: A generic Card Draw module for LogiosBot

=head1 DESCRIPTION
A module to be used by LogiosBot for basic card drawing. This uses files to define decks, so you can add deck types at any time. 

=head1 USEAGE
!cards new French52
			response: Your new French52 deck is deck1
!cards new French54
			response: Your new French54 deck is deck2
!cards draw 1 from deck1
			response: Your card is Three of Clubs
!cards draw 51 from deck1
			[response snipped]
!cards draw 1 from deck1
			response: The deck is empty! 
!cards shuffle deck1
			response: The deck is now shuffled
!cards draw 1 from deck1
			response: Your card is Two of Hearts

=head1 Author
Yamikuronue - yamikuronue at gmail.com

=head1 LICENSE
GPL 3.0. See LogiosBot.pl for details. 


=cut
use Math::Random::MT;
my $random;
%Decks;
%Decktypes;
my $nextint = 1;

BEGIN {
	$VERSION = 1.0;
	$Config::modules{'LogiosCards'} = 1;
	$random = Math::Random::MT->new(time());
}



#Examine - all modules must have this. Takes a string for input, a channel, and a nick for who said it
sub examine {
	my $input = shift;
	my $channel = shift;
	my $nick = shift;

	$input =~ s/\s+$//;
	if ($input =~ /^!cards (.+)/i) {
		$input = $1;
		if ($input =~ /^help (\w+)/) {
			topic_help($channel,$1);
		}
		elsif ($input =~ /help/) {
			help($channel);
		}
		elsif ($input =~ /^new (\w+)/i) {
			new_deck($nick, $channel,$1);
		}
		elsif ($input =~ /^draw (\d+) from (\w+)/i) {
			draw_card($nick, $channel,$1,$2);
		}
		elsif ($input =~ /^shuffle (\w+)/i) {
			shuffle_deck($nick, $channel,$1);
		}
		return 1;
	}		
	elsif ($input =~ /^!LogiCards$/) {
		module_info($channel);
		return 1;
	}
	else {
		return 0;
		#input not important;
	}
}

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "LogiosDice version $VERSION. Copyright 2011. Created by Yami Kuronue.");
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
	$helppath = File::Spec->catfile( @dirs, "cardshelp.txt" );
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

sub new_deck {
	my($nick) = shift;
	my($chan) = shift;
	my($type) = shift;
	
	
	$filename = $Config::CardsDirectory . $type . ".txt"; 
	if (!(-e $filename)) { 
		Logios::IRC_print($chan, "Deck " . $type . " not found.");
		return;
	}	
	
	my $deckname = "deck" . $nextint++;
	make_deck($deckname, $filename);
	
	$Decktypes{$deckname} = $type;
	Logios::IRC_print($chan, "Deck " . $deckname . " created (Type: " . $type . ")");
}

sub make_deck {
	my($deckname) = shift;
	my($filename) = shift;
	
	my @deck = read_file($filename);
	
	$Decks{$deckname} = [@deck];
}

sub draw_card {
	my($nick) = shift;
	my($chan) = shift;
	my($num) = shift;
	my($deck) = shift;
	
	my $numcards = scalar(@{$Decks{$deck}});
	
	if (!defined $Decks{$deck}) {
		Logios::IRC_print($chan, "No such deck: " . $deck);
		return;
	}
	
	if ($numcards == 0) {
		Logios::IRC_print($chan, "The deck is empty!");
	} elsif ($num > $numcards) {
		Logios::IRC_print($chan, "Cannot draw " . $num . " cards, deck only has " . $numcards . " remaining.");
	} else {
	
		my @theDeck = @{$Decks{$deck}};
		my $iterator = 0;
		while ($iterator < $num) {
			my $card = splice(@theDeck, $random->rand($numcards), 1);
			Logios::IRC_print($chan, "Your card is " . $card);
			$iterator++; $numcards--;
		}
		$Decks{$deck} = [@theDeck]; #Save the altered deck back to our deck list
	}	
}

sub shuffle_deck {
	my($nick) = shift;
	my($chan) = shift;
	my($deck) = shift;
	
	if (!defined $Decks{$deck}) {
		Logios::IRC_print($chan, "No such deck: " . $deck);
		return;
	}

	$filename = $Config::CardsDirectory . $Decktypes{$deck} . ".txt"; 
	if (!(-e $filename)) { 
		Logios::IRC_print($chan, "Deck " . $type . " not found.");
		return;
	}	
	
	make_deck($deck, $filename);
	Logios::IRC_print($chan, "Deck " . $deck . " is now shuffled.");
}
1;
