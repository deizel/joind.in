# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = 'centos-62-64-puppet'
  config.vm.box_url = 'http://packages.vstone.eu/vagrant-boxes/centos/6.2/centos-6.2-64bit-puppet-vbox.4.1.12.box'

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port 80, 8080

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"

  # Pass custom arguments to VBoxManage before booting VM
  config.vm.customize [
    'modifyvm', :id, '--chipset', 'ich9', # solves kernel panic issue on some host machines
    # '--uartmode1', 'file', 'C:\\base6-console.log' # uncomment to change log location on Windows
  ]

  # Pass installation procedure over to Puppet (see `puppet/manifests/joindin.pp`)
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.module_path = "puppet/modules"
    puppet.manifest_file = "joindin.pp"
    puppet.options = [
      '--verbose',
      # '--debug',
      # '--graph',
      # '--graphdir=/vagrant/puppet/graphs'
    ]
  end
end
