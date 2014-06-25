#Copyright (C) 2011  Bayley Green (hereafter known as Yami Kuronue)

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl

use File::Copy;
require("Logios_Config.pm");
#Hermes Module Installer
#To use: from the command line, run "module_installer.pm Folder"
#That will install the module located in Folder



#0-indexed array
if ($#ARGV < 0) {
	print "usage:module_installer Folder\n";
	print "number of arguments: $#ARGV \n";
	exit;
}

print "Installing from: $ARGV[0] \n";

my $folder = @ARGV[0];
opendir (DIR, $folder) or die "Invalid folder: " . $!;

while ($filename = readdir(DIR)) {
      next if ($filename =~ m/^\./);

	($volume, $directories,$file) = File::Spec->splitpath( $Config::install_Directory );
	@outdirs = File::Spec->splitdir( $directories );
	@indirs = File::Spec->splitdir( $directories );
	push(@indirs,$folder);

      if ($filename =~ m/\.pm$/) {
	  $from = File::Spec->catfile(@indirs,$filename);
	  $to = File::Spec->catfile(@outdirs, $filename);
	  print "Installing module $filename \n";
	  copy($from,$to);
      }

      if ($filename =~ m/help.txt$/) {
	  push(@outdirs,"Help");
	  $from = File::Spec->catfile(@indirs,$filename);
	  $to = File::Spec->catfile(@outdirs, $filename);
	  print "Installing help $filename \n";
	  copy($from,$to);
      }

}