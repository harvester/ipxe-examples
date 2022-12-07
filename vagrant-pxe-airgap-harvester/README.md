Harvester iPXE Boot Using Vagrant Libvirt
=========================================

Introduction
------------

**Note:** if you do not desire to have an environment air-gapped it is strongly-encouraged to simply run the `vagrant-pxe-harvester` ipxe-example over this one - as this one is not *only* **more** resource intensive but will take a **substantially** long time to provision and *currently* has some known issues.

**Also Note:** this set up with the `settings.yml` is currently intended to run with `rancher_config.run_single_node_rancher`, `rancher_config.run_single_node_air_gapped_rancher`, and `harvester_network_config.offline` set to `true` - there are known issues with the setup not working if those values are changed.

Utilizing [Vagrant][vagrant], [KVM][kvm], and [Ansible][ansible] to create a
ready-to-play virtual Harvester & Rancher environment for evaluation and testing
purposes. Two Vagrant VMs will be created by default, PXE server and a
single or multi-node Harvester respectively - with the optional vm for the Rancher instance with baked in Docker Registry, K3s & Helm installed Rancher.

Sample Host Loadout
-------------
A sample host load-out for an Ubuntu based distro (22.04 LTS), running this with 1 to 4 Harvester Nodes can look something like the following:
- Installing dependencies such as:
  - `sshpass qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager libvirt-dev wget tmux apt-transport-https ca-certificates curl software-properties-common ansible neovim libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev ruby-libvirt qemu libvirt-daemon-system libvirt-clients ebtables dnsmasq-base libguestfs-tools`
  - `sudo usermod -a -G libvirt $(whoami)`
  - `sudo vim /etc/libvirt/libvirtd.conf`:
    - `unix_sock_group = "libvirt"`
    - `unix_sock_rw_perms = "0770"`
    - `sudo systemctl restart libvirtd.service`
    - ensuring logging out and logging back in
    - `ansible-galaxy collection install community.general`
    - `vagrant plugin install vagrant-libvirt`
    - ensuring a `known_hosts` file is present in `~/.ssh/known_hosts` for the sake of the provisioning leveraging `sshpass`, so possible creation could be something like `touch ~/.ssh/known_hosts` if not present
- then finally running `./setup_harvester.sh -c` , provided any edits have been made as desired to the `settings.yml` file prior to kicking off the script



Prerequisites
-------------

-   ansible-base >= 2.10.0 & ansible-core >= 2.11.0
-   Vagrant \>= 2.0.3.
-   vagrant-libvirt plugin \>= 0.0.43 and \<= 0.8.2 (NOTE: Anything above 0.8.2 currently breaks the Vagrantfile loadout with libvirt)
-   KVM (i.e. qemu-kvm), preferably the latest and greatest. This
    environment was tested with qemu-kvm 2.11.
-   Host with at least 16 CPU, 64GB RAM, and 500GB free disk space. (note: running this is **very** resource intensive depending on the number of nodes)
-   To run with Rancher either airgapped or not airgapped you need to have installed `sshpass` \>=1.06-1
-   Ansible Galaxy's Community General module, `ansible-galaxy collection install community.general` , the community.general module must be installed
-   Libvirt 'default' network will need to be enabled / autostarted [libvirt default network](https://wiki.libvirt.org/Networking.html#id2)

Quick Start
-----------
1. You can edit the `settings.yml` to change:
    - `rancher_config.run_single_node_rancher` to `true` to enable running a single node non-airgapped Rancher instance, if you would like to airgap that Rancher instance you would set `rancher_config.run_single_node_air_gapped_rancher` to `true` as well
    - `node_disk_size` for `rancher_config` is thin provisioned (so it won't truly take up the entire space), but if running air-gapped would need a minimum of 300G
    - other options should be self documenting
2. Then you can run `./setup_harvester.sh` **NOTE:** you more than likely will want to pass the flag `-c` or `--clean-ssh-known-hosts` so that when the additional configuration on each Harvester node runs after standing up Rancher old-host information is cleaned up, ex: `./setup_harvester.sh -c`, since cleaning the known_hosts file is a local file, the flag is optional, because you may want to manipulate that local file yourself instead of having this script manipulate that local file
3.  You then can navigate to `https://<harvester_vip>:30443` to access the harvester UI. **NOTE:** by default harvester_vip is 192.168.2.131. However, it is configureable in settings.yml.
4.  You can also navigate to (from settings.yml) 'rancher_config.rancher_install_domain' to access the Air-Gapped Rancher UI.

Running RKE2 Air-Gapped
---------
1. When working to set up an RKE2 instance air-gapped on Harvester you will want to utilize an image that has `qemu guest agent` already installed (something like [opensuse-leap-nocloud](https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.4/images/openSUSE-Leap-15.4.x86_64-1.0.1-NoCloud-Build2.163.qcow2)) as packages and outbound communication is cut off
1. You'll want to follow the [test-steps-section](https://harvester.github.io/tests/manual/harvester-rancher/68-fully-airgapped-rancher-integrate-harvester-no-proxy/) starting on step 5/6

Known Issues
-------------
- Sometimes provisioning will fail, possibly due to any number of elements, when provisioning fails, currently, the only way to recover is to simply remove and restart with something-like `vagrant destroy -f` and then rerunning the setup harvester script
- If the provisioning fails at `TASK [rancher : Run the equivalent of "apt-get update" as a separate step, first]`, this is usually due to the outbound network calls needed to download packages having an issue, there may be an issue with the network that the VM is on and/or network bandwidth and/or issues with the mirrors used to download the packages for the vm
- This has remained mostly tested with Rancher v2.6.X - anything beyond that may encounter un-forseen provisioning issues
- In settings.yaml `rancher_config.run_single_node_rancher`, `rancher_config.run_single_node_air_gapped_rancher`, and `harvester_network_config.offline` set to something other than `true`, causes issues with provisioning
- If VMs are shutdown or restarting them (even something like an air-gapped upgrade) - currently breaks the load-out, currently if any of the VMs are shut down or restarted after provisioning `rke2-coredns` edits become lost and will need to be manually re-applied [rke2-coredns comment](https://github.com/harvester/harvester/issues/3731#issuecomment-1487866103)
- It is best to manually apply `containerd-registry` edits (via settings in Harvester) as a safeguard prior to importing Harvester into Rancher:
```json
{
    "Mirrors": {
        "docker.io": {
            "Endpoints": ["myregistry.local:5000"],
            "Rewrites": null
        }
    },
    "Configs": {
        "myregistry.local:5000": {
            "Auth": null,
            "TLS": {
                "CAFile": "",
                "CertFile": "",
                "KeyFile": "",
                "InsecureSkipVerify": true
            }
        }
    },
    "Auths": null
}
```
- For hostname resolution it is best to ensure on your `/etc/hosts` file there is the edit to include the hostnames associated to the ip (cross-ref: `settings.yml`):
```
192.168.2.34    rancher-vagrant-vm.local        myregistry.local
```
- fully-air-gapped access to the private docker registry running on `settings.yml's rancher_config.registry_domain` may end up not resolving, you can navigate to the `rancher_config.node_harvester_network_ip` at: `https://myregistry.local:5000/v2/_catalog?n=500`.
- rke1/rke2 downstream provisioning using harvester might pose some problems, they're actively being investigated, some elements of [the "Test steps" in fully-argapped Harvester w/ fully-airgapped Rancher integration may work](https://harvester.github.io/tests/manual/harvester-rancher/68-fully-airgapped-rancher-integrate-harvester-no-proxy/)
- k9s tar.gz is installed if needed on the `rancher_config.node_harvester_network_ip` in `/home/vagrant/k9s_Linux_x86_64.tar.gz` - you can access the Rancher instance shell via: `ssh vagrant@192.168.2.34` with password: `vagrant` - you could change the ownership to `vagrant` on the tar.gz file, extract it, and then use it in conjunction with K3s.  Something like `sudo chmod 755 /etc/rancher/k3s/k3s.yaml` then within the `/home/vagrant` directory, running `./k9s --kubeconfig /etc/rancher/k3s/k3s.yaml`


Troubleshooting
-------------
- validate links to:
  - Rancher's private docker-registry: `https://myregistry.local:5000/v2/_catalog?n=500` (audit catalog, look for items like `rancher-agent`, that image is crucial in allowing Harvester to be imported into Rancher)
  - check local cluster events on Harvester VIP: `https://192.168.2.131/dashboard/c/local/explorer#cluster-events`, (if importing Harvester into Rancher, check to see if `Pulling image "myregistries.local:5000/rancher/rancher-agent"` message exists in events on cluster)
- check disk space, depending on N nodes, provisioning **"can"** fail due to not enough disk space (again this is resource intensive)
- if issues connecting to Rancher instance, validate `/etc/hosts` for hostname resolution
- if issues surrounding `ssl` check that `containerd-registry` edits have been made to allow for `insecure` registry
- if restarted any vms by "accident", and routing is not working with prior imported Harvester & Rancher, check applying rke2-coredns edits manually [rke2-coredns comment](https://github.com/harvester/harvester/issues/3731#issuecomment-1487866103) again

Acknowledgements
----------------

-   The Vagrant iPXE environment idea was borrowed from
    <https://github.com/eoli3n/vagrant-pxe>.


[ansible]: https://www.ansible.com
[kvm]: https://www.linux-kvm.org
[vagrant]: https://www.vagrantup.com
