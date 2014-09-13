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
	if ($input =~ /^!roll besm ?(.+)?/i) {
		Logios::log("Received dice roll");
		besm_dice($nick, $channel,$1);
		return 1;
	}
	elsif ($input =~ /^!LogiCards (.+)/i) {
		$input = $1;
		if ($input =~ /^help (\w+)/) {
			topic_help($channel,$1);
		}
		elsif ($input =~ /help/) {
			help($channel);
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
		Logios::IRC_print($where, "Deck " . $type . " not found.");
		return;
	}	
	
	#open my $handle, '<', $filename;
	my @deck = read_file($filename);
	#close $handle;
	
	my $deckname = "deck" . $nextint++;
	$Decks{$deckname} = [@deck];
	Logios::IRC_print($where, "Deck " . $deckname . " created (Type: " . $type . ")");
}

sub draw_card {
	my($nick) = shift;
	my($chan) = shift;
	my($num) = shift;
	my($deck) = shift;
	
	if ($num > $Decks{$deck}) {
		Logios::IRC_print($where, "The deck is empty!");
		return;
	}
	
	my iterator = 0;
	while (iterator < $num) {
		
	}
	
}


1;
