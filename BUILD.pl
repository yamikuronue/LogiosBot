 use Module::Build;
  my $build = Module::Build->new
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