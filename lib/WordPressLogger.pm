package WordPressLogger;

#To use the RPC server
use XMLRPC::Lite;
use Data::Dumper;
use POSIX qw(strftime);
use File::Slurp;
use HTML::Escape;

BEGIN {
	$VERSION = 1.1;
	$Config::modules{'WordPressLogger'} = 1;
}

sub examine {
	my $input = shift;
	my $channel = shift;
	my $nick = shift;
	
	$input =~ s/\s+$//;
	if ($input =~ /^!wp (.+)/i) {
		$input = $1;
	} elsif ($input =~ /^!Wordpress (.+)/i) {
		$input = $1;
	} elsif ($input =~ /^!Wordpress$/i || $input =~ /^!wp$/i) {
		module_info($channel);
		#return 1;
	}else {
		#return 0;
		#input not important;
	}

	if ($input =~ /^help (\w*)/i) {
		topic_help($channel,$1);
	}
	elsif ($input =~ /^help$/i) {
		help($channel);
	}
	elsif ($input =~ /^upload (\w*)/i) {
		Hermes::log("Received upload request");
		log_upload($channel, $1);
	}
	elsif ($input =~ /^debug/i) {
		Hermes::log("Received debug request");
		#debug($channel, $1);
	}
	 else {
		return 0;
	}
	return 1; #If we didn't ignore the input above, we're not returning false
}

sub module_info {
	my $where = shift;
	Hermes::IRC_print($where, "Wordpress via RPC version $VERSION. Copyright 2013. Created by Yami Kuronue.");
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
	
	open FILE, $Config::install_Directory . "/Help/wphelp.txt";
	@filearray=<FILE>;
	close(FILE);

	foreach $line (@filearray) {
		if ($line =~ /^$what\t(.+)/i) {
			$response = $1;
			$found = 1;
		}
	}
	
	if ($found) {
		Hermes::IRC_print($where, $response);
	} else {
		Hermes::IRC_print($where, "Command not found. Help Commands for commands");
	}
}

sub log_upload {
	my $where = shift;
	my $what = shift;

	$filename = $Config::logdir . "session" . $what . ".txt";
	unless (-e $filename) {
		 Hermes::IRC_print($where, "Log Doesn't Exist!" );
		 return;
	} 

	my $date = strftime "%m/%d/%Y", localtime;
	my $text = read_file($filename);
	
	#Sanitize input for wordpress
	$text = escape_html($text);
	$text =~ s/[^[:print:]]+//g; 
	
	my $results = XMLRPC::Lite
		->proxy($Config::wpurl . "xmlrpc.php")
		->call("wp.newPost", 0, $Config::wpusername, $Config::wppassword, {
				post_type => 'post',
				post_status => 'draft',
				post_title => 'IRC Session Log: Posted ' . $date,
				post_content => $text
			})
		->result;
		
	Hermes::IRC_print($where, "Success! Log posted as post number " . $results);
}
1;