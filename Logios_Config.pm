package Config;

BEGIN {
	$VERSION = 1.0;
	%modules = %Logios::modulebackup;
}

###################BEGIN CUSTOMIZABLE CONFIG#################

#Program data
#Required:
#   install_Directory: the directory in which Logios is installed
#   logfile: the file to use for logging normal behavior
#   errorfile: the file to use for logging errors. 
$install_Directory = "/home/Logiosbot";
$logfile = "Logios.log";
$errorfile = "error.log";

#Connection data
#Required:
#    botnick: the nick you want the bot to use when connecting
#    server: The server to connect to
#    port: The port to use for connecting. Usually 6667.
#    @channels: An array of channels to join on connect
$botnick = 'LogiosTest';
$server = 'localhost';
$port = '6667';
@channels = ('#outsiders_ooc','#muelsfell_tomu');


#Personalized data
#Required:
#     password: The kill password to emergency shutdown the bot or make administrative changes.
$password = 'Logios'; 

#modules
#Required:
#     %modules = %Logios::modulebackup;  #Restores modules from backup in the event of a module reload.
#					Used for hot-swapping modules
#     $modules{ 'Config' } = 1;   Reports that the config file is loaded
#     @modulefiles:  A list of external modules to load. 
%modules = %Logios::modulebackup;
$modules{ 'Config' } = 1;

@modulefiles = ('TvTropes.pm','LogiDice.pm','logfunctions.pm','personality.pm','Apples.pm');



####Advanced####
#Socket Data
#Required:
# 	socketfile: The file to use as a socket to communicate with plugins
$socketfile = '/tmp/logiossocket';



################END CUSTOMIZABLE CONFIG#################

#A few routines just for compliance
sub examine {
	my $text = shift;
	my $channel = shift;
	
	$text =~ s/\s+$//;
	
	if ($text =~ /^!Config$/i) {
		module_info($channel);
		return 1;
	}
	return 0;
}

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "Config file for Logios.");
}

sub list_modules {
	my $where = shift;
	my $output = "Modules: ";
	foreach $mod (sort keys %modules) {
		$output .= $mod . " ";
	}
	Logios::IRC_print($where, $output);
}
1;
