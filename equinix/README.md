This document provides steps to deploy a Harvester cluster on [Equinix Metal](https://metal.equinix.com/) platform.

The Equinix Metal platform allows users to use external iPXE script files to provision nodes. We'll demonstrate creating a Harvester cluster by booting iPXE scripts from the user's Github repository. 

## Prepare the repository

Fork this repository to the user's GitHub organization and clone it locally.

## Modify the iPXE scripts

Edit the `ipxe-install` file:

```
#!ipxe
dhcp
iflinkwait -t 5000 && echo Detected link on ${ifname} 
set version master # change to a specific version for production installation
set base https://releases.rancher.com/harvester/${version}  # ipxe on Equinix currently does not support `https://release.rancher.com`, you can build your own web server or use other methods to download related artifacts.
kernel ${base}/harvester-${version}-vmlinuz-amd64 ip=dhcp net.ifnames=1 rd.cos.disable rd.noverifyssl root=live:${base}/harvester-${version}-rootfs-amd64.squashfs harvester.install.networks.harvester-mgmt.interfaces="hwAddr:${net0/mac}" harvester.install.networks.harvester-mgmt.method=dhcp harvester.install.networks.harvester-mgmt.bond_options.mode=balance-tlb harvester.install.networks.harvester-mgmt.bond_options.miimon=100 console=ttyS1,115200 harvester.install.automatic=true harvester.install.skipchecks=true boot_cmd="echo include_ping_test=yes >> /etc/conf.d/net-online" harvester.install.config_url=https://metadata.platformequinix.com/userdata
initrd ${base}/harvester-${version}-initrd-amd64
boot
```

The URLs after `kernel` and `initrd` tell the iPXE program to boot kernel and initrd image from these URL. We use the official images here. If the user doesn't need to change the URL, the forked repository can be left as it is. If the user needs to use different images, please modify the URLs and commit the `ipxe-install` file. Then push back to the forked repository.

The `console=ttyS1,115200` parameter tells the installer ttyS1 is the primary console, since it's the only console that end users can use on Equinix Metal (the [SOS console](https://metal.equinix.com/developers/docs/resilience-recovery/serial-over-ssh/)).

The `harvester.install.automatic=true` parameter tells the installer we want to do the automatic installation.

The `harvester.install.skipchecks=true` parameter tells the installer to skip preflight hardware checks.

The `harvester.install.config_url=https://metadata.platformequinix.com/userdata` parameter tells the installer we want to fetch the Harvester configuration from this URL, which contains the userdata specified by the user when creating nodes. The harvester configuration contains sensitive credentials. We can prevent those credentials from leaking by using [userdata](https://metal.equinix.com/developers/docs/servers/user-data/) that can only be seen by provisioning nodes.

**Note:** Due to a known [certificate issue](https://github.com/harvester/harvester/issues/2226), ipxe on Equinix currently does not support `https://release.rancher.com`, you can build your own web server or use other methods to download related artifacts.

## Create servers on Equinix

### Configure Elastic IP
- Select `IPs & Networks` from the menu bar, and then click `IP`.
- Click `Request IP Addresses`.
- Select `Public IPv4` item for deployment type.
- Select the `Location` to be new.
- The quantity should be **less than or equal to 31**.
- Click `Submit Request` and wait to get the Elastic IP.

### Create a new cluster

- Select `Custom iPXE` option for the Operating System.
- In `Custom iPXE Settings`
  - Input URL to the `ipxe-install` file into the `IPXE Script URL` field.
  - Do not enable the `Persist PXE as the first boot option after provisioning.` option.
- Type a hostname (optional).
- In `Optional Settings`
  - Enable `Add User Data` option, paste the Harvester configuration to it. The following is an example:

    ```yaml
    #cloud-config
    token: token           # replace with a desired token
    os:
      ssh_authorized_keys:
      - ssh-rsa ...        # replace with your public key
      password: p@ssword   # replace with a your password
      ntp_servers:
      - 0.suse.pool.ntp.org
      - 1.suse.pool.ntp.org
    install:
      mode: create
      device: /dev/sda
      iso_url: https://releases.rancher.com/harvester/master/harvester-master-amd64.iso
      tty: ttyS1,115200n8
      vip: <server_public_ip> # use Elastic IP
      vip_mode: static
    ```
    - The [userdata file](./userdata-create.yaml) is included in the source and the user can modify it according to any need.
    - The Harvester installer doesn't require the `#cloud-config` line at the beginning, but Equinix Metal validates if the userdata contains it.
    - The `vip` parameter is required.
  - To configure Elastic IP for `Public IPv4`, enable `Configure IPs`, select `Deploy from your subnet` and select that the `Subnet Size` should be less than or equal to 31.
  ![configure-ips](configure-ips.png)

- Click `Deploy Now`
- The user can use the SOS console of the provisioned server to see the installation process.
- The Harvester GUI can be accessed at `https://<server_public_ip>`.


### Join an existing cluster

The procedure to create new servers to join an existing Harvester cluster is similar to the one that creates a new cluster.

The only difference is in the [userdata](./userdata-join.yaml):

```yaml
#cloud-config
server_url: https://<new_cluster_server_ip>:443
token: token  # replace with the token you set when creating a new cluster
os:
  ssh_authorized_keys:
  - ssh-rsa ...  # replace with your public key
  password: p@ssword  # replace with a your password
install:
  mode: join
  networks:
    harvester-mgmt: # The management bond name. This is mandatory.
      interfaces:
      - name: eth0
      default_route: true
      method: dhcp
  device: /dev/sda
  iso_url: https://releases.rancher.com/harvester/master/harvester-master-amd64.iso
  tty: ttyS1,115200n
```

**NOTE:** two fields are different:

- `server_url`: In the previous step, we create a new server to start a new Harvester cluster, use that server's public IP address here.
- `install.mode`: Should be `join`.

**NOTE:** the user can create multiple servers to join a cluster with the same userdata at once.


