Harvester iPXE Boot Using Vagrant Libvirt
=========================================

Introduction
------------

Utilizing [Vagrant][vagrant], [KVM][kvm], and [Ansible][ansible] to create a
ready-to-play virtual Harvester environment for evaluation and testing
purposes. Two Vagrant VMs will be created by default, PXE server and a
single-node Harvester respectively.

Prerequisites
-------------

-   Ansible \>= 2.9.0. This environment was tested with Ansible 2.9.5.
-   Vagrant \>= 2.0.3.
-   vagrant-libvirt plugin \>= 0.0.43.
-   KVM (i.e. qemu-kvm), preferably the latest and greatest. This
    environment was tested with qemu-kvm 2.11.
-   Host with at least 16 CPU, 64GB RAM, and 500GB free disk space. (note: running this is **very** resource intensive depending on the number of nodes)

Installing Vagrant
------------------

Vagrant documentation has a [section](https://developer.hashicorp.com/vagrant/install) describing how to install it on various platforms. But if you are using openSUSE Tumbleweed, following specific steps outlined below might help.

At the time of writing this, latest version of Vagrant is 2.4.3.

1. Download the RPM from the [releases page](https://releases.hashicorp.com/vagrant/2.4.3/) and install it using
  `rpm -i`. Installing a package outside of the package management tool `zypper`
  will mark it for deletion on the next run of `zypper dist-upgrade`. To prevent
  this, add a lock using:
    ```sh
    $ sudo zypper addlock vagrant
    ```
2. Install dependencies for vagrant libvirt plugin which we need to create virtual machines:
    ```sh
    $ sudo zypper install qemu libvirt libvirt-devel
    ```
3. Install the plugin:
    ```sh
    $ vagrant plugin install vagrant-libvirt
    ```

### Troubleshooting

A common error while attempting to install vagrant-libvirt plugin is:
```
Vagrant failed to install the requested plugin because it depends
on development files for a library which is not currently installed
on this system. The following library is required by the 'vagrant-libvirt'
plugin:

libvirt

If a package manager is used on this system, please install the development
package for the library. The name of the package will be similar to:

libvirt-dev or libvirt-devel

After the library and development files have been installed, please
run the command again.
```
In spite of installing `libvirt` and `libvirt-devel`, the error is complaining about their inexistence. Enable the debug mode:
```sh
$ vagrant plugin install vagrant-libvirt --debug
Building native extensions. This could take a while...
Building native extensions. This could take a while...
WARN manager: Failed to install plugin: ERROR: Failed to build gem native extension.

    current directory: /root/.vagrant.d/gems/3.3.6/gems/ruby-libvirt-0.8.4/ext/libvirt
/opt/vagrant/embedded/bin/ruby extconf.rb
checking for pkg-config for libvirt... not found
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.

[...]

extconf.rb:6:in `<main>': libvirt library not found in default locations (RuntimeError)

To see why this extension failed to compile, please check the mkmf.log which can be found here:

/root/.vagrant.d/gems/3.3.6/extensions/x86_64-linux/3.3.0/ruby-libvirt-0.8.4/mkmf.log

extconf failed, exit code 1
```
It asks to look at `mkmf.log` file for more details. Exact path might differ on your system. In the `mkmf.log` file, see if there is an error message like below:
```
/bin/sh: symbol lookup error: /opt/vagrant/embedded/lib/libreadline.so.8: undefined symbol: UP
```
If you do see that message, delete the file in question and try installing the pluging again:
```sh
$ rm /opt/vagrant/embedded/lib/libreadline.so.8

$ vagrant plugin install vagrant-libvirt 
```

Quick Start
-----------

1.  Edit `settings.yml` to make sure the configuration satisfies your
    needs. The options are self-documented.
    Set `harvester_cluster_nodes` to `1` if you just want to try out
    Harvester quickly and don't need a full cluster.
    To deploy a Rancher node additionally, set `rancher_config.enabled` to `true`.
2.  Run `setup_harvester.sh` to deploy the Harvester cluster and additional configured nodes.
    This may take a while (i.e. 30 minutes depending on configuration).
3.  If successful, run `vagrant status` to see the status of the Vagrant
    boxes.
4.  Point your browser to `https://<harvester_vip>:30443` to
    access the Harvester UI. Just ignore the scary SSL warnings for now
    as it is using self-signed certificates for demo purposes.
    *NOTE*: by default `harvester_vip` is `192.168.0.131`. However, it is
    configurable in `settings.yml`.
5.  If you have deployed a Rancher node, you can access the UI
    at https://192.168.0.141.
    The bootstrap password to finish the installation can be found in
    `settings.yml`.
6.  Note, when starting up the VM's again, you need to specify the
    nodes explicitly, e.g. `vagrant up rancher pxe_server harvester-node-0 [harvester-node-X]`

Acknowledgements
----------------

-   The Vagrant iPXE environment idea was borrowed from
    <https://github.com/eoli3n/vagrant-pxe>.


[ansible]: https://www.ansible.com
[kvm]: https://www.linux-kvm.org
[vagrant]: https://www.vagrantup.com
