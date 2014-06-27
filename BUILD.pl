 use Module::Build;

  my $logiosBuild = Module::Build->subclass(
      class => "Module::Build::Custom",
      code => <<'SUBCLASS' );

      sub ACTION_install {
        my $self = shift;

        create_config($self->blib, $self->install_path(".pm"));
        $self->SUPER::ACTION_install
      }

 
 sub create_config {
    my $configdir = shift;
    my $install_directory = shift;
    my $filename = ">" . $configdir . "/lib/Logios_Config.pm";
    my $input;

    print "Now entering the configuration file creation script.";
    unless(open FILE,  $filename ) {
      die "nUnable to write config file $filename :  $!";
    }

    print FILE "package Config; \n";
    print FILE "BEGIN {\n";
    print FILE "  \$VERSION = 1.0;\n";
    print FILE "  \%modules = \%Logios::modulebackup;\n";
    print FILE "}\n\n";

    print FILE "\$install_Directory = \"";
    print FILE $install_directory;
    print FILE "\";\n"; 

    getValueAndWrite("Log file name", "\$logfile", "Logios.log");
    getValueAndWrite("Error file name", "\$errorfile", "error.log");


  }

  sub getValueAndWrite {
    my $promt = shift;
    my $itemName = shift;
    my $default = shift;

    print $itemName . "? [" . $default . "]";
    $input = <>;
    chomp($input);
    print FILE "\$" . $itemName . " = \"" . ($input ? $input : $default) . "\"\n";
  }

SUBCLASS


  my $build = $logiosBuild->new
    (
     module_name => 'LogiosBot',
     license  => 'gpl',
     requires => {
                  'POE'          => 0,
                  'POE::Component::IRC'  => 0,
                  'Module::Reload'  => 0,
                  'Math::Expression::Evaluator'  => 0,
                  'File::Spec'  => 0,
                  'Findbin'  => 0,
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
    );
  $build->create_build_script;

