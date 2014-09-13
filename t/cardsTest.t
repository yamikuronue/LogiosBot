###Pretend to be a config file
package Config;
our $CardsDirectory = "/vagrant/lib/Modules/LogiCards/";

package Testing;

use Test::More;
use Test::MockModule;
use FindBin;
use lib "$FindBin::Bin/../lib/Modules/LogiCards"; 

my $mockRand;
BEGIN {
	$mockRand = Test::MockModule->new('Math::Random::MT');
	use_ok(LogiCards);
}


#Test deck generation
#Valid
$install_Directory = "/var";
ok(keys(%LogiosCards::Decks) == 0, "No decks at start");
LogiosCards::new_deck("nick","chan","French52");
ok(keys(%LogiosCards::Decks) == 1, "One deck after adding");
ok(ref $LogiosCards::Decks{"deck1"} eq "ARRAY", "Deck added is an array");
ok($Logios::last_out eq "Deck deck1 created (Type: French52)", "Output correct when adding invalid deck");

#Invalid
LogiosCards::new_deck("nick","chan","NonExistant");
ok(keys(%LogiosCards::Decks) == 1, "Still one deck after adding an invalid");
ok($Logios::last_out eq "Deck NonExistant not found.", "Output correct when adding invalid deck");


done_testing();

###Useful randomizer subroutines
sub gen_rand {
	my @values = @_;
	my $counter = 0;
	return sub {
		#diag("Randomizer returning " . $values[$counter]);
		return $values[$counter++]-1;  #because 0 is valid, the dice roller assumes that 0 is a roll of 1, so will add 1 to the result
	}
}



###Pretend to be a logios bot
package Logios;
use Test::More;

our $last_out;
sub log {
	#do nothing
}

sub IRC_print {
	my $where = shift;
	my $message = shift;
	$last_out = $message;
	#diag("Output: " . $message);
}