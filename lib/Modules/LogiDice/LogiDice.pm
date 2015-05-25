package LogiosDice;

=pod

=head1 NAME
LogiosDice: A dice module for LogiosBot

=head1 DESCRIPTION
A module to be used by LogiosBot for simple dice rolls. This can roll any side of dice, as well as shortcuts for Scion, World of Darkness, and BESM game systems. 

=head1 USEAGE
Normal dice: !roll XdY[+/-]Z.
Scion: !roll scion X[+/-]Y where X is the size of the dice pool and Y is any automatic successes or failures
White wolf: !roll ww X[+/-]Y where X is the size of the dice pool and Y is any automatic successes or failures
BESM: !roll besm X where X is the dice modifier

=head1 Author
Yamikuronue - yamikuronue at gmail.com

=head1 LICENSE
GPL 3.0. See LogiosBot.pl for details. 


=cut

#LogiosDice: Your basic dice module for Logiosbot
use Math::Random::MT;
use Math::Expression::Evaluator;
my $random;

BEGIN {
	$VERSION = 1.75;
	$Config::modules{'LogiosDice'} = 1;
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
	elsif ($input =~ /^!roll scion (.+)/i) {
		Logios::log("Received dice roll");
		scion_dice($1, $nick, $channel);
		return 1;
	}
	elsif ($input =~ /^!roll ww (.+)/i) {
		Logios::log("Received dice roll");
		ww_dice($1, $nick, $channel);
		return 1;
	}
	elsif ($input =~ /^!roll (.+)/i) {
		Logios::log("Received dice roll");
		roll_dice($1,$nick,$channel);
		return 1;
	} elsif ($input =~ /^!scion (.+)/i) {
		Logios::log("Received dice roll");
		scion_dice($1, $nick, $channel);
		return 1;
	} elsif ($input =~ /^!wwdice (.+)/i) {
		Logios::log("Received dice roll");
		ww_dice($1, $nick, $channel);
		return 1;
	} elsif ($input =~ /^!besm ?(.+)?/i) {
		Logios::log("Received dice roll");
		besm_dice($nick, $channel,$1);
		return 1;
	}
	elsif ($input =~ /^!LogiosDice (.+)/i) {
		$input = $1;
		if ($input =~ /^help (\w+)/) {
			topic_help($channel,$1);
		}
		elsif ($input =~ /help/) {
			help($channel);
		}
		return 1;
	}		
	elsif ($input =~ /^!LogiosDice$/) {
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
	$helppath = File::Spec->catfile( @dirs, "dicehelp.txt" );
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

sub besm_dice {
	my($nick) = shift;
	my($chan) = shift;
	my($addsub) = shift;
	
	#BESM uses a flat 2d6 +/- some extra junk. 
	roll_dice("2d6".$addsub, $nick, $chan);
}

sub scion_dice {
	my $input = shift;
	my $who = shift;
	my $where = shift;
	my $diestring, my $comments, my $total, my $output;
	
	($diestring, $comments) = split(/\s/,$input,2);
	
	#parse input string into dice
	if (!($diestring =~ /[\+\-]/)) {
		$diestring .= "d10";
	} else {
		$diestring =~ s/([\+\-])/d10\1/;
	}
	($total,$output) = parse($diestring,"scion");
	Logios::log("Rolled " . $total);

	
	Logios::IRC_print($where,$who . " rolled " . $diestring . $comments . " || " . $output . " || Total: \x02" . $total . " successes\x02");
}

sub ww_dice {
	my $input = shift;
	my $who = shift;
	my $where = shift;
	my $diestring, my $comments, my $total, my $output;
	
	($diestring, $comments) = split(/\s/,$input,2);
	
	
	if (!($diestring =~ /[\+\-]/)) {
		$diestring .= "d10";
	} else {
		$diestring =~ s/([\+\-])/d10\1/;
	}
	($total,$output) = parse($diestring,"ww");
	Logios::log("Rolled " . $total);

	
	Logios::IRC_print($where,$who . " rolled " . $diestring . $comments . " || " . $output . " || Total: \x02" . $total . " successes\x02");
}

sub roll_dice {
	my $input = shift;
	my $who = shift;
	my $where = shift;
	my $diestring, my $comments, my $total, my $output;
	
	($diestring, $comments) = split(/\s/,$input,2);
	($total,$output) = parse($diestring,"sum");
	Logios::log("Rolled " . $total);

	
	Logios::IRC_print($where,$who . " rolled " . $input . " || " . $output . " || Total: \x02" . $total . "\x02");
	#Logios::IRC_print($where,"Returned output: " . $output);
	

}

sub parse {
	my $string = shift;
	my $mode = shift;
	my ($total, $output, $expr);
	#This is a general arithmatic parser with order of operations precedence
	#It introduces two new operators:
	# d : rolls the left-hand input number of dice of size equal to the right-hand input and returns the result
	# x: does the right-hand operation the lefthand number of times
	
	#Order of operations: [Parens not supported]
	# x
	# d
	# *, /
	# +, -
	
	#sanity checks
	if (!($string =~ /\d/)
		|| !($string =~ /[+\-*\/dx]/)) {
			return ($string, "No operations");
	}
	
	#Operator: X
	if ($string =~ /x/i) {
		#Safety first!
		my @recurses = $string =~ /x/g;
		my $recursioncount = @recurses;
		if ($recursioncount > 3) {
			return("-1", "Too many x's, please refactor.");
		}
		
		
		my ($left,$right) = split(/x/,$string,2);
		my $first = 1;
		if ($left > 20) {
			return("-1", "Too many repetitions, please refactor.");
		}
		
		for (my $i = 0; $i < $left; $i++) {
			my ($subtotal, $suboutput) = parse($right,$mode);
			$total += $subtotal;
			if ($first) {
				$first = 0;
			} else {
				$output .= " || ";
			}
			$output .= $suboutput . " | Subtotal: \x02" . $subtotal . "\x02" ;
		}
		return($total,$output);
	}
	
	my $first = 1;
	$expr = $string;
	#Operator: D
	while ($expr =~ /(\d+d\d+)/i) {
		my ($dice) = $1;
		my ($subtotal, $suboutput) = roll($dice, $mode);
		if ($first) {
			$first = 0;
		} else {
			$output .= " || ";
		}
		$optoperator = substr($string, index($string,$dice)-1, 1);
		if ($optoperator eq "+" || $optoperator eq "-" || $optoperator eq "*" || $optoperator eq "/") { $output .= $optoperator; }
		$output .= $suboutput;
		$expr =~ s/$dice/$subtotal/;
		$string =~ s/$dice//;
	}
	#Fate dice
	while ($expr =~ /(\d+dF)/i) {
		my ($dice) = $1;
		my $real_dice = $dice;
		$real_dice =~ s/F/6/;
		my ($subtotal, $suboutput) = roll($real_dice, "fate");
		$suboutput =~ s/d6/dF/;
		
		if ($first) {
			$first = 0;
		} else {
			$output .= " || ";
		}
		$optoperator = substr($string, index($string,$dice)-1, 1);
		if ($optoperator eq "+" || $optoperator eq "-" || $optoperator eq "*" || $optoperator eq "/") { $output .= $optoperator; }
		$output .= $suboutput;
		$expr =~ s/$dice/$subtotal/;
		$string =~ s/$dice//;
	}
	#Operator: *, /
	while ($string =~ m/([\*\/])(\d+)/gi) {
		my ($operator, $right) = ($1, $2);
		$output .= " || " . $operator . "\x02" . $right . "\x02";
	}
	
	#Operator: +, -
	while ($string =~ m/([+-])(\d+)(?!d)/gi) {
		my ($operator, $right) = ($1, $2);
		$output .= " || " . $operator . "\x02" . $right . "\x02";
	}
	
	#remove any stray letters and spaces
	$expr =~ s/[A-Za-z\s]//g;
	$total = Math::Expression::Evaluator->new->parse($expr)->val;
	return ($total, $output);
}

sub roll {
	my $dice = shift;
	my $mode = shift;
	my $left, my $right;
	my $total, my $output, my $dicelist;
	my $successes = 0;
	my $rerolls = 0;
	
	
	
	Logios::log("Rolling " . $dice);
	if (!($dice =~ /d/)) {
		Logios::log("Roll returns " . $dice);
		return ($dice,"\x02".$dice."\x02");
	}
	($left, $right) = split(/d/,$dice,2);

	#Precondition for fate
	if ($mode =~ /fate/ && $right != 6) {
		return (0, "invalid size for F dice!")
	}
	if ($left =~ /d/) {
		($left,$loutput) = roll($left,$mode);
		$output .= $loutput . " || ";
	}

	if ($right =~ /d/) {
		($right,$routput) = roll($right,$mode);
		$output .= $routput . " || ";
	}


	$total = 0;
	$dicelist = "";
	
	#san checks
	if ($left > 100) { $left = 100 };
	if ($right > 1000) { $right = 1000};
	
	$rerolls = 0;
	for (my $i = 0; $i < $left; $i++) {
		my $currdice = int($random->rand($right) + 1);
		if ($mode =~ /sum/) {$total += $currdice};
		if ($mode =~ /fate/) {
			if ($currdice == 5 || $currdice == 6) { $total++ };
			if ($currdice == 1 || $currdice == 2) { $total-- };
		}
		$dicelist = $dicelist . $currdice . " ";
		if (($mode =~ /scion/ || $mode =~ /ww/) && $currdice >= 8) {
			$successes++;
		} elsif($mode =~ /scion/ && $currdice == 7) {
			#Scion counts 7s
			$successes++;
		}
		if ($currdice == 10) {
			if ($mode =~ /scion/) { 
				$successes++;
			} elsif ($mode =~ /ww/) {
				$rerolls++;
			}
		}

	}
	
	#do rerolls
	if ($rerolls > 0) {
		$dicelist .= "|| Exploding dice: ";
	}
	while ($rerolls > 0) {
		my $currdice = int($random->rand($right) + 1);
		$rerolls--;
		$dicelist = $dicelist . $currdice . " ";
		if (($mode =~ /scion/ || $mode =~ /ww/) && $currdice >= 8) {
			$successes++;
		}
		if ($currdice == 10) {
			$rerolls++;
		}
	}

	
	if ($mode =~ /sum/) {
		$output .= $left . "d" . $right . ": " . $dicelist;
		$output .= "= \x02" . $total . "\x02";
	}
	
	
	if ($mode =~ /fate/) {
		$dicelist =~ s/[12]/[\x02-\x02]/g;
		$dicelist =~ s/[34]/[\x020\x02]/g;
		$dicelist =~ s/[56]/[\x02+\x02]/g;
		
		$output .= $left . "d" . $right . ": " . $dicelist;
		$output .= "= \x02" . $total . "\x02";
	}
	
	if ($mode =~/scion/ || $mode =~/ww/) {
		#bold successes
		$dicelist =~ s/7/\x027\x02/g;
		$dicelist =~ s/8/\x028\x02/g;
		$dicelist =~ s/9/\x029\x02/g;
		$dicelist =~ s/10/\x0210\x02/g;
		
		#reappend
		$output = $left . "d" . $right . ": " . $dicelist;
		$output .= "= \x02" . $successes . "\x02 successes";
		
		#return the right total
		$total = $successes;
		
		if ($rerolls > 0) {
			$output .= " and \x02" . $rerolls . "\x02 rerolls";
		}
	}
	
	Logios::log("Roll returns " . $total);
	return ($total,$output);
}
1;
