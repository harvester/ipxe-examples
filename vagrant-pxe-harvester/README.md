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
-   Host with at least 16 CPU, 64GB RAM, and 500GB free disk space.

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

Running With Single Node Air-Gapped Rancher & Harvester Node
-----------
1.  As above, edit `settings.yml` to make sure the configuration satisfies your
    needs. The options are self-documented.
2.  Run `setup_harvester.sh` - this can take 2hrs+ to set up an Air Gapped Rancher instance and Harvester Node
3.  You then can navigate to `https://<harvester_vip>:30443` to access the harvester UI.
4.  You can also navigate to (from settings.yml) 'rancher_config.rancher_install_domain' to access the Air-Gapped Rancher UI.
5.  Then you can add an air-gapped Harvester cluster to the air-gapped Rancher instance.

Acknowledgements
----------------

-   The Vagrant iPXE environment idea was borrowed from
    <https://github.com/eoli3n/vagrant-pxe>.


[ansible]: https://www.ansible.com
[kvm]: https://www.linux-kvm.org
[vagrant]: https://www.vagrantup.com
