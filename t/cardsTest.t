###Pretend to be a config file
package Config;
use FindBin;
our $CardsDirectory = "$FindBin::Bin/../lib/Modules/LogiCards/";

package Testing;

use Test::More;
use Test::MockModule;
use FindBin;
use lib "$FindBin::Bin/../lib/Modules/LogiCards"; 
use Data::Dumper;

my $mockRand;
BEGIN {
	$mockRand = Test::MockModule->new('Math::Random::MT');
	use_ok(LogiCards);
}


####Test deck generation
#Valid
$install_Directory = "/var";
ok(keys(%LogiosCards::Decks) == 0, "No decks at start");
LogiosCards::new_deck("nick","chan","French52");
ok(keys(%LogiosCards::Decks) == 1, "One deck after adding");
ok(ref $LogiosCards::Decks{"deck1"} eq "ARRAY", "Deck added is an array");
ok($Logios::last_out eq "Deck deck1 created (Type: French52)", "Output correct when adding invalid deck");
is(scalar(@{$LogiosCards::Decks{"deck1"}}),52,"French52 has 52 cards");

#Invalid
LogiosCards::new_deck("nick","chan","NonExistant");
ok(keys(%LogiosCards::Decks) == 1, "Still one deck after adding an invalid");
ok($Logios::last_out eq "Deck NonExistant not found.", "Output correct when adding invalid deck");


###Test card draw
$Logios::num_outputs = 0;
LogiosCards::draw_card("nick","chan",1,"deck1");
ok($Logios::last_out =~ /Your card is/, "Card draw format correct");
is($Logios::num_outputs,1, "Only one card output when drawing one card.");

$Logios::num_outputs = 0;
LogiosCards::draw_card("nick","chan",50,"deck1");
is($Logios::num_outputs,50, "50 cards output when drawing 50.");

$Logios::num_outputs = 0;
LogiosCards::draw_card("nick","chan",2,"deck1");
ok($Logios::last_out =~ /^Cannot draw 2 cards, deck only has 1 remaining.$/, "Deck should be empty when drawing 2 cards after drawing 51");
is($Logios::num_outputs,1, "Only one output when drawing 2 cards but deck is empty");

LogiosCards::draw_card("nick","chan",1,"deck1");
ok($Logios::last_out =~ /Your card is/, "Can draw 1 after drawing 51");
LogiosCards::draw_card("nick","chan",1,"deck1");
ok($Logios::last_out =~ /The deck is empty!/, "Cannot draw 1 after drawing 52");

###Test shuffle
LogiosCards::shuffle_deck("nick","chan","deck1");
ok($Logios::last_out =~ /Deck deck1 is now shuffled./, "Deck can be shuffled");
$Logios::num_outputs = 0;
LogiosCards::draw_card("nick","chan",2,"deck1");
ok($Logios::last_out =~ /Your card is/, "Can draw 2 after shuffling empty deck");
is($Logios::num_outputs,2, "2 cards output when drawing 2 after shuffle.");

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

our $num_outputs;
our $last_out;
sub log {
	#do nothing
}

sub IRC_print {
	my $where = shift;
	my $message = shift;
	$last_out = $message;
	$num_outputs++;
	#diag("Output: " . $message);
}