package AutoID;

=pod

=head1 NAME
AutoID: An auto identifier for Logiosbot.

=head1 DESCRIPTION
A module for LogiosBot that identifies to its nick when asked.

=head1 USEAGE
Place the following variables in the config file:
$NickServName = "NickServ" #or whatever
$NickServPassword = "Password" #or what you'd like it to identify as
This will catch all messages from NickServName and try to identify with the Password

=head1 Author
Yamikuronue - yamikuronue at gmail.com
 


=cut
BEGIN {
	$VERSION = 1.0;  #version number for the module
	$Config::modules{'AutoID'} = 1;  #Name of the module goes here
	$NickServName = $Config::NickServName;
	$NickServPassword = $Config::NickServPassword;
} 


our $NickServName, $NickServPassword;

sub examine {
	my $text = shift;
	my $where = shift;
	my $who = shift;
	my $type = shift;

	if ($who eq $NickServName) {
	    Logios::IRCPrint(NickServName,"IDENTIFY " . $NickServPassword);
	    return 1;
	}

        return 0;
}

sub module_info {
	my $where = shift;
	Logios::IRC_print($where, "AutoID version $VERSION. Created by Yami Kuronue.");
}