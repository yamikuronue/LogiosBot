use Test::More;
use Test::MockModule;
use FindBin;
use lib "$FindBin::Bin/../lib/Modules/LogiDice"; 

my $mockRand;
BEGIN {
	$mockRand = Test::MockModule->new('Math::Random::MT');
	use_ok(LogiDice);
}


##Roll tests##
my ($total, $output);

#One die
($total, $output) = LogiosDice::roll("1d6","sum");
ok(0 < $total && $total < 7, "1d6 should be between 0 and 7 exclusive") or diag("We somehow rolled a total of " . $total . " instead");

#two die
($total, $output) = LogiosDice::roll("2d6","sum");
ok(1 < $total && $total < 13, "2d6 should be between 1 and 13 exclusive") or diag("We somehow rolled a total of " . $total . " instead");

#red die
($total, $output) = LogiosDice::roll("1d20","sum");
ok(0 < $total && $total < 21, "1d20 should be between 0 and 21 exclusive") or diag("We somehow rolled a total of " . $total . " instead");

#blue die
($total, $output) = LogiosDice::roll("1d2","sum");
ok(0 < $total && $total < 3, "1d2 should be between 0 and 3 exclusive") or diag("We somehow rolled a total of " . $total . " instead");

#Max 100 dice
($total, $output) = LogiosDice::roll("400d2","sum");
ok(100 <= $total && $total <= 200, "Only 100 dice rolled at most") or diag("We somehow rolled a total of " . $total . " instead");

#max die size is 1k
($total, $output) = LogiosDice::roll("1d4000","sum");
ok(1 <= $total && $total <= 1000, "Max dice size capped at 1000") or diag("We somehow rolled a total of " . $total . " instead");

#ww mode counts successes, let's be sure 
$mockRand->mock('rand' => gen_rand(1,1,1));
($total, $output) = LogiosDice::roll("3d10","ww");
ok($total == 0, "WhiteWolf mode can return 0 successes") or diag ("Reported " . $total . " successes instead.");
ok($output eq "3d10: 1 1 1 = \x02".$total."\x02 successess", "WhiteWolf mode reports no successes correctly") or diag ("Reported '" . $output . "' instead.");

$mockRand->mock('rand' => gen_rand(9,9,9));
($total, $output) = LogiosDice::roll("3d10","ww");
ok($total == 3, "WhiteWolf mode can return 3 successes") or diag ("Reported " . $total . " successes instead.");
ok($output eq "3d10: \x029\x02 \x029\x02 \x029\x02 = \x02".$total."\x02 successess", "WhiteWolf mode reports successes correctly") or diag ("Reported '" . $output . "' instead.");

$mockRand->mock('rand' => gen_rand(7,7,7));
($total, $output) = LogiosDice::roll("3d10","ww");
ok($total == 0, "WhiteWolf mode does not count 7 as success") or diag ("Reported " . $total . " successes instead.");

$mockRand->mock('rand' => gen_rand(9,9,10,9));
($total, $output) = LogiosDice::roll("3d10","ww");
ok($total == 4, "WhiteWolf mode can explode dice to return 4 successes on 3 rolls") or diag ("Reported " . $total . " successes instead.");

#scion mode also counts successes, but differently
$mockRand->mock('rand' => gen_rand(1,1,1));
($total, $output) = LogiosDice::roll("3d10","scion");
ok($total == 0, "Scion mode can return 0 successes") or diag ("Reported " . $total . " successes instead.");
ok($output eq "3d10: 1 1 1 = \x020\x02 successess", "Scion mode reports no successes correctly") or diag ("Reported '" . $output . "' instead.");

$mockRand->mock('rand' => gen_rand(9,9,9));
($total, $output) = LogiosDice::roll("3d10","scion");
ok($total == 3, "Scion mode can return 3 successes") or diag ("Reported " . $total . " successes instead.");
ok($output eq "3d10: \x029\x02 \x029\x02 \x029\x02 = \x02".$total."\x02 successess", "Scion mode reports successes correctly") or diag ("Reported '" . $output . "' instead.");

$mockRand->mock('rand' => gen_rand(7,7,7));
($total, $output) = LogiosDice::roll("3d10","scion");
ok($total == 3, "Scion mode counts 7 as success") or diag ("Reported " . $total . " successes instead.");

#Scion dice do not explode, but ten counts twice
$mockRand->mock('rand' => gen_rand(9,9,10,10,10,9));
($total, $output) = LogiosDice::roll("3d10","scion");
ok($total == 4, "Scion mode cannot explode dice") or diag ("Reported " . $total . " successes instead.");


###Parsing tests###
#Basic dice
$mockRand->mock('rand' => gen_rand(4));
($total, $output) = LogiosDice::parse("1d10","sum");
ok($total == 4, "Parse rolls one die correctly");
ok($output eq "1d10: 4 = \x024\x02", "Parse gives correct output for one die") or diag($output);;

$mockRand->mock('rand' => gen_rand(4,8));
($total, $output) = LogiosDice::parse("2d10","sum");
ok($total == 12, "Parse rolls two die correctly");
ok($output eq "2d10: 4 8 = \x0212\x02", "Parse gives correct output for two dice") or diag($output);;

#addition and subtraction of constants
$mockRand->mock('rand' => gen_rand(4,8));
($total, $output) = LogiosDice::parse("2d10+2","sum");
ok($total == 14, "Parse adds numbers correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || +\x022\x02", "Parse gives correct output when adding") or diag($output);;

$mockRand->mock('rand' => gen_rand(4,8));
($total, $output) = LogiosDice::parse("2d10-2","sum");
ok($total == 10, "Parse subtracts numbers correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || -\x022\x02", "Parse gives correct output when subtracting") or diag($output);;

#addition and subtraction of dice
$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10+1d4","sum");
ok($total == 14, "Parse adds dice correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || +1d4: 2 = \x022\x02", "Parse gives correct output when adding dice") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10-1d4","sum");
ok($total == 10, "Parse subtracts dice correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || -1d4: 2 = \x022\x02", "Parse gives correct output when subtracting dice") or diag($output);

#addition and subtraction of dice and constants
$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10+1d4+2","sum");
ok($total == 16, "Parse adds dice and nums correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || +1d4: 2 = \x022\x02 || +\x022\x02", "Parse gives correct output when adding dice and nums") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10-1d4-2","sum");
ok($total == 8, "Parse subtracts dice and nums correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || -1d4: 2 = \x022\x02 || -\x022\x02", "Parse gives correct output when subtracting dice and nums") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10+1d4-2","sum");
ok($total == 12, "Parse adds dice and subtracts nums correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || +1d4: 2 = \x022\x02 || -\x022\x02", "Parse gives correct output when adding dice and subtracting nums") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10-1d4+2","sum");
ok($total == 12, "Parse subtracts dice and adds nums correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || -1d4: 2 = \x022\x02 || +\x022\x02", "Parse gives correct output when subtracting dice and adding nums") or diag($output);

#multiplication and division by constants
$mockRand->mock('rand' => gen_rand(4,8));
($total, $output) = LogiosDice::parse("2d10*2","sum");
ok($total == 24, "Parse multiplies numbers correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || *\x022\x02", "Parse gives correct output when multiplying") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8));
($total, $output) = LogiosDice::parse("2d10/2","sum");
ok($total == 6, "Parse divides numbers correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || /\x022\x02", "Parse gives correct output when dividing") or diag($output);

#multiplication and division by dice
$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10*1d4","sum");
ok($total == 24, "Parse multiplies by dice correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || *1d4: 2 = \x022\x02", "Parse gives correct output when multiplying by dice") or diag($output);

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10/1d4","sum");
ok($total == 6, "Parse divides by dice correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || /1d4: 2 = \x022\x02", "Parse gives correct output when dividing by dice") or diag($output);

#Order of operations
($total, $output) = LogiosDice::parse("1+2*3*4","sum");
ok($total == 25, "Parse delegates basic math correctly");

$mockRand->mock('rand' => gen_rand(4,8,2));  
($total, $output) = LogiosDice::parse("2d10+1*2","sum");
ok($total == 14, "Parse divides by dice correctly");
ok($output eq "2d10: 4 8 = \x0212\x02 || *\x022\x02 || +\x021\x02", "Parse gives correct output when dividing by dice") or diag($output);

#Invalid input testing
$mockRand->mock('rand' => gen_rand(2,4,8));
($total, $output) = LogiosDice::parse("quidditch","sum");
ok($total == 0, "Parse returns 0 for alphabetic input with a 'd'") or diag("Total was: " . $total);
ok($output eq "No operations", "Parse gives correct output when given incorrect input") or diag("Output was: " . $output);

$mockRand->mock('rand' => gen_rand(2,4,8));
($total, $output) = LogiosDice::parse("elephant","sum");
ok($total == 'elephant', "Parse returns input when it cannot be parsed at all") or diag("Total was: " . $total);
ok($output eq "No operations", "Parse gives correct output when given incorrect input") or diag("Output was: " . $output);


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

sub log {
	#do nothing
}