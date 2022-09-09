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

Troubleshoooting & Known Issues
-------------
- fully-air-gapped may provision but navigating to the `settings.yml's rancher_config.rancher_install_domain` may end up not resolving, this can be fixed by temporarily adding the hostname something-like, `192.168.0.34	rancher-vagrant-vm.local` to the bottom of your `/etc/hosts` file
- fully-air-gapped access to the private docker registry running on `settings.yml's rancher_config.registry_domain` may end up ont resolving, you can navigate to the `rancher_config.node_harvester_network_ip` at: `https://rancher_config.node_harvester_network_ip:5000/v2/_catalog` or additionally add it to the bottom of your `/etc/hosts` file locally something like: `192.168.0.34	rancher-vagrant-vm.local myregistry.local`
- rke1/rke2 downstream provisioning using harvester might pose some problems, they're actively being investigated, some elements of [the "Test steps" in fully-argapped Harvester w/ fully-airgapped Rancher integration may work](https://harvester.github.io/tests/manual/harvester-rancher/68-fully-airgapped-rancher-integrate-harvester-no-proxy/)
- k9s tar.gz is installed if needed on the `rancher_config.node_harvester_network_ip` in `/home/vagrant/k9s_Linux_x86_64.tar.gz` - you can access the Rancher instance shell via: `ssh vagrant@192.168.0.34` with password: `vagrant` - you could change the ownership to `vagrant` on the tar.gz file, extract it, and then use it in conjunction with K3s.  Something like `sudo chmod 755 /etc/rancher/k3s/k3s.yaml` then within the `/home/vagrant` directory, running `./k9s --kubeconfig /etc/rancher/k3s/k3s.yaml` 
- Rancher instance provisioning is not idempotent, re-running can cause issues

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
