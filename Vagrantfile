# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise32"


  #First, we need to install chef and dependencies (including make)
	config.vm.provision "shell",
		inline: "apt-get install make",
		privileged: true
 
	#Now we can use chef to add perl
	  config.vm.provision "chef_solo" do |chef|
		chef.add_recipe "perl"
	  end
	
	#A few custom modules
	config.vm.provision "shell",
		inline: "cpan -j /vagrant/CPANConfig.pm install local::lib"
	config.vm.provision "shell",
		inline: "cpan -j /vagrant/CPANConfig.pm install Module::Build"
end
