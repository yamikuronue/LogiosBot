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

BEGIN {
	$VERSION = 1.75;
	$Config::modules{'LogiosDice'} = 1;
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

	
	Logios::IRC_print($where,$who . " rolled " . $diestring . $comments . " || " . $output . " || Total: \x02" . $total . " successess\x02");
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

	
	Logios::IRC_print($where,$who . " rolled " . $diestring . $comments . " || " . $output . " || Total: \x02" . $total . " successess\x02");
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
	my ($left, $right, $ltotal, $rtotal, $loutput, $routput);
	my ($total, $output);
	
	Logios::log("Parsing " . $string);
	

	#First split on + or - to give individual tokens
	#sample inputs: 1d6, 1d6+4, 1d6-3, 1d6+1d4+12, 1d20-1d4+13, et cetera. 
	my $plus = rindex($string,'+');
	my $minus = rindex($string,'-');
	
	if ($plus == -1 && $minus == -1) {
		($total,$output) = roll($string,$mode);
		Logios::log("total is " . $total);
		return ($total,$output);
	}
	if ($plus > $minus) {
		#($left,$right) = split(/\+/,$string,2);   #This seemed intuitive, but it created bugs with order of operations
		$right = substr($string,$plus+1);
		$left = substr($string,0,$plus);
		
		($rtotal, $routput) = parse($right,$mode);
		if (length($left) == 0) { 
			return ($rtotal,$routput);
		};
		($ltotal,$loutput) = parse($left,$mode);
		
		Logios::log("add total is " . $ltotal+$rtotal);
		return ($ltotal+$rtotal,$loutput." || +".$routput);
	} else {
		#($left,$right) = split('-',$string,2);
		$right = substr($string,$minus+1);
		$left = substr($string,0,$minus);
		
		($rtotal, $routput) = parse($right,$mode);
		if (length($left) == 0) { 
			return (0-$rtotal,$routput);
		};
		($ltotal,$loutput) = parse($left,$mode);

		Logios::log("subtract total is " . $ltotal-$rtotal);
		return ($ltotal-$rtotal,$loutput." || -".$routput);
	}
	

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
	
	if ($dice =~/x/) {
		my $num, my $string, my $subtotal, my $minioutput;
		($num,$string) = split(/x/,$dice,2);
		$output = "";
		if ($num > 100) { $num = 100 };
		Logios::log("num " . $num . " string " . $string);
		for (my $i = 0; $i < $num; $i++) {
			Logios::log("Loop " . $i);
			($subtotal,$minioutput) = roll($string,$mode);
			$total += $subtotal;
			if ($output == "") {
				$output = $minioutput;
			} else {
				$output .= " | " . $minioutput;
			}
			
		}
		Logios::log("Meta Roll returns " . $total);
		return ($total,$output);
	} else {
	
		($left, $right) = split(/d/,$dice,2);
	
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
		for (my $i = 0; $i < $left; $i++) {
			my $currdice = int(rand($right) + 1);
			$total += $currdice;
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
	
		$output .= $left . "d" . $right . ": " . $dicelist;
		if ($mode =~ /sum/) {
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
			$output .= "= \x02" . $successes . "\x02 successess";
			
			#return the right total
			$total = $successes;
			
			if ($rerolls > 0) {
				$output .= " and \x02" . $rerolls . "\x02 rerolls";
			}
		}
	
		
		Logios::log("TEST: " . $output);
		Logios::log("Roll returns " . $total);
		return ($total,$output);
	}
	
}

1;
