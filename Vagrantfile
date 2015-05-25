# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	# Every Vagrant virtual environment requires a box to build off of.
	config.vm.box = "hashicorp/precise32"

	#Networking
	config.vm.network "private_network", type: "dhcp"

	##PROVISIONING##
	#Some of the below commands fail because we haven't run an update
	config.vm.provision "shell",
		inline: "apt-get update",
		privileged: true

	#First, we need to install make
	config.vm.provision "shell",
		inline: "apt-get -y install make",
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
		
	#Because dependency install is annoying
	config.vm.provision "shell",
		inline: "perl Build.pl"
		
	config.vm.provision "shell",
		inline: "yes || ./Build installdeps"
end
