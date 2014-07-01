use Module::Build;

  my $logiosBuild = Module::Build->subclass(
      class => "Module::Build::Custom",
      code => <<'SUBCLASS' );
	  
	  use File::Copy "copy";
	  use File::Spec::Functions qw(catfile splitpath splitdir);
	  
      sub ACTION_install {
        my $self = shift;

		print "Would you like to create a custom config file? [Y/n]";
		$input = <STDIN>;
		chomp($input);
		if ($input eq "" || $input eq "y" || $input eq "Y") {
			create_config($self->blib, $self->install_path(".pm"));
		} else {
			copy($self->blib . "/lib/Sample_Logios_Config.pm",
				$self->blib . "/lib/Logios_Config.pm");
		}
        $self->SUPER::ACTION_install
      }

 
 sub create_config {
    my $configdir = shift;
    my $install_directory = shift;
    my $filename = ">" . $configdir . "/lib/Logios_Config.pm";
    my $input;
	
    unless(open FILE,  $filename ) {
      die "Unable to write config file $filename :  $!";
    }

    print FILE "package Config; \n";
    print FILE "BEGIN {\n";
    print FILE "  \$VERSION = 1.0;\n";
    print FILE "  \%modules = \%Logios::modulebackup;\n";
    print FILE "}\n\n";

    print FILE "\$install_Directory = \"";
    print FILE $install_directory;
    print FILE "\";\n"; 

    getValueAndWrite("Log file name", "logfile", "Logios.log");
    getValueAndWrite("Error file name", "errorfile", "error.log");

	getValueAndWrite("Nickname for the bot to use", "botnick", "LogiosTest");
	getValueAndWrite("Server to connect to", "server", "irc.darkmyst.org");
	getValueAndWrite("Port to connect on", "port", "6667");
	getMultipleValuesAndWrite("List of channels to join automatically", "channels");
	
	getValueAndWrite("Admin password", "password", "Logios");
	
	print FILE "\%modules = \%Logios::modulebackup;\n";
	print FILE "\$modules{ 'Config' } = 1;\n";
	
	#Modules#
	print "Installing modules....\n";
	$moduleDir = $configdir . "/lib/Modules";
	
	my $modulelist = "";
	$first = 1;
	opendir (MODULEDIR, $moduleDir) or die "Invalid Module folder: " . $!;
	while ($filename = readdir(MODULEDIR)) {
		next if ($filename =~ m/^\.\.?$/);
		if (!$first) {
			$modulelist = $modulelist . ",";
		}
		$modulelist = $modulelist . "'" . installModuleAndGetName($moduleDir . "/" . $filename, $install_directory) . "'";
		$first = 0;
	}

	print FILE "\@modulefiles = (" . $modulelist . ");\n";
	
	#End of file
	 print FILE <<'FILEFOOTER';
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
FILEFOOTER
	close FILE;
  }

  sub getValueAndWrite {
    my $prompt = shift;
    my $itemName = shift;
    my $default = shift;

    print $prompt . "? [" . $default . "]  ";
    $input = <STDIN>;
    chomp($input);
    print FILE "\$" . $itemName . " = \"" . ($input ? $input : $default) . "\"\n";
  }
  
  sub getMultipleValuesAndWrite {
	my $prompt = shift;
    my $itemName = shift;
	my $first = 1;
	
	print FILE "\@" . $itemName . "=(";
	print $prompt . "? (enter for end of list)";
	
	my $input = <STDIN>;
	chomp($input);
	
	while ($input ne "") {
		if (!$first) {
			print FILE ",";
		}
		print FILE "'" . $input . "'";
		print "?";
		$input = <STDIN>;
		chomp($input);
		$first = "0";
	}
	
	print FILE ");\n";
  }
  
  sub installModuleAndGetName {
	my $folder = shift;
	my $install_directory = shift;
	my $moduleFile;
	opendir (DIR, $folder) or die "Invalid folder $folder: " . $!;

	while ($filename = readdir(DIR)) {
		next if ($filename =~ m/^\./);

		($volume, $directories,$file) = splitpath( $install_Directory );
		@outdirs = splitdir( $directories );
		@indirs = splitdir( $directories );
		push(@indirs,$folder);

		if ($filename =~ m/\.pm$/) {
			$from = catfile(@indirs,$filename);
			$to = catfile(@outdirs, $filename);
			print "Installing module $filename to $to\n";
			copy($from,$to);
			$modulefile = $filename;
		}

		if ($filename =~ m/help.txt$/) {
			push(@outdirs,"Help");
			$from = catfile(@indirs,$filename);
			$to = catfile(@outdirs, $filename);
			print "Installing help $filename \n";
			copy($from,$to);
		}
	}
	
	return $moduleFile;
}

SUBCLASS


  my $build = $logiosBuild->new
    (
     module_name => 'LogiosBot',
     license  => 'gpl',
     requires => {
				'POE'  => 0,
				'POE::Component::IRC'  => 0,
				'Module::Reload'  => 0,
				'Math::Expression::Evaluator'  => 0,
				'File::Spec'  => 0,
				'FindBin'  => 0,
			},
	recommends => {
				'Math::Random::MT' => 0,
				'LWP::Simple' => 0,
				'LWP::UserAgent' => 0,
				'HTTP::Request' => 0,
				'HTTP::Response' => 0,
				'HTML::LinkExtor' => 0,
				'XMLRPC::Lite' => 0,
				'Data::Dumper' => 0,
				'POSIX' => 0,
				'File::Slurp' => 0,
			},
	build_requires => {
				'File::Copy' => 0,
				'File::Find::Rule' => 0
			}
    );
  $build->create_build_script;