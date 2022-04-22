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
-   vagrant-libvirt plugin \>= 0.0.43 and \<= 0.8.2 (NOTE: Anything above 0.8.2 currently breaks the Vagrantfile loadout with libvirt)
-   KVM (i.e. qemu-kvm), preferably the latest and greatest. This
    environment was tested with qemu-kvm 2.11.
-   Host with at least 16 CPU, 64GB RAM, and 500GB free disk space.
-   To run with Rancher either airgapped or not airgapped you need to have installed `sshpass` \>=1.06-1
-   Ansible Galaxy's Community General module, `ansible-galaxy collection install community.general` , the community.general module must be installed

Quick Start
-----------

1.  Edit `settings.yml` to make sure the configuration satisfies your
    needs. The options are self-documented.
2.  Run `setup_harvester.sh`. This may take awhile (i.e. 30 minutes
    depending on configuration).
3.  If successful, run `vagrant status` to see the status of the Vagrant
    boxes.
4.  Point your browser to `https://<harvester_vip>:30443` to
    access the Harvester UI. Just ignore the scary SSL warnings for now
    as it is using self-signed certificates for demo purposes.
    *NOTE*: by default `harvester_vip` is `192.168.0.131`. However, it is
    configureable in `settings.yml`.

Running With A Single Node Rancher Instance
-----------
1. You can edit the `settings.yml` to change:
    - `rancher_config.run_single_node_rancher` to `true` to enable running a single node non-airgapped Rancher instance, if you would like to airgap that Rancher instance you would set `rancher_config.run_single_node_air_gapped_rancher` to `true` as well
    - `node_disk_size` for `rancher_config` is thin provisioned (so it won't truly take up the entire space), but if running air-gapped would need a minimum of 300G
    - other options should be self documenting
2. Then you can run `./setup_harvester.sh` **NOTE:** you more than likely will want to pass the flag `-c` or `--clean-ssh-known-hosts` so that when the additional configuration on each Harvester node runs after standing up Rancher old-host information is cleaned up, ex: `./setup_harvester.sh -c`, since cleaning the known_hosts file is a local file, the flag is optional, because you may want to manipulate that local file yourself instead of having this script manipulate that local file
3.  You then can navigate to `https://<harvester_vip>:30443` to access the harvester UI.
4.  You can also navigate to (from settings.yml) 'rancher_config.rancher_install_domain' to access the Air-Gapped Rancher UI.

Acknowledgements
----------------

-   The Vagrant iPXE environment idea was borrowed from
    <https://github.com/eoli3n/vagrant-pxe>.


[ansible]: https://www.ansible.com
[kvm]: https://www.linux-kvm.org
[vagrant]: https://www.vagrantup.com
