# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise32"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  

  #First, we need to install chef and dependencies (including make)
	Vagrant.configure("2") do |config|
		config.vm.provision "shell",
			inline: "apt-get install make",
			privileged: true
	end
 
	#Now we can use chef to add perl
	Vagrant.configure("2") do |config|
	  config.vm.provision "chef_solo" do |chef|
		chef.add_recipe "perl"
	  end
	end
	
	#A few custom modules
	Vagrant.configure("2") do |config|
		config.vm.provision "shell",
			inline: "cpan -j /vagrant/CPANConfig.pm install local::lib"
		config.vm.provision "shell",
			inline: "cpan -j /vagrant/CPANConfig.pm install Module::Build"
		end
end
