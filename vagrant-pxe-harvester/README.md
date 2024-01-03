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
