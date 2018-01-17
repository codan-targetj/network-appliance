# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box_download_insecure = true

    config.vm.define "appliance" do |mo|
        mo.vm.box = "debian/jessie64"
        mo.vm.hostname = "minetec"
        mo.vm.boot_timeout = 500
        
        if Vagrant.has_plugin?("vbguest")
          mo.vbguest.auto_update = false
        end
        mo.vm.synced_folder ".", "/vagrant", 
                            type: "rsync", rsync__args: [ '-r' ], mount_options: [ 'dmode=777', 'fmode=666' ]

        # provisioning steps
        mo.vm.provision "bootstrap", type: "shell", inline: "sh /vagrant/provision/bootstrap.sh"
    end
end
