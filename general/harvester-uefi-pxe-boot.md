# Harvester PXE Boot via libvirt + iPXE (UEFI)

## Boot Flow

```
UEFI Firmware
  │
  ▼  DHCP request (no user-class)
dnsmasq  ──→  responds with ipxe.efi (TFTP)
  │
  ▼  TFTP download
ipxe.efi executes
  │
  ▼  DHCP request (user-class: iPXE)
dnsmasq  ──→  responds with boot script URL (HTTP)
  │
  ▼  HTTP fetch boot script
iPXE executes script
  │
  ▼  HTTP download kernel + initrd
Harvester installer runs
```

The key point is that dnsmasq must respond differently to two separate DHCP requests from the same MAC:
- **Stage 1** — UEFI firmware, no user-class → serve `ipxe.efi` via TFTP
- **Stage 2** — iPXE loaded, user-class = `iPXE` → serve boot script URL via HTTP

---

## Prerequisites

### 1. Download ipxe.efi

```bash
curl -o /var/lib/libvirt/dnsmasq/ipxe.efi https://boot.ipxe.org/x86_64-efi/ipxe.efi
ls -lh /var/lib/libvirt/dnsmasq/ipxe.efi
# Must be ~1MB+. If it's a few KB, it's broken.
```

### 2. Verify OVMF has HTTP boot support (optional)

If you want UEFI to fetch `ipxe.efi` directly over HTTP (without TFTP), your OVMF binary must include `HttpBootDxe`:

```bash
strings /usr/share/qemu/ovmf-x86_64-code.bin | grep -i HttpBoot
```

If no output, your OVMF does not support UEFI HTTP boot. Use the TFTP approach described in this guide instead — it works identically.

---

## libvirt Network Configuration

```xml
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <!-- TFTP server for serving ipxe.efi -->
    <dnsmasq:option value='enable-tftp'/>
    <dnsmasq:option value='tftp-root=/var/lib/libvirt/dnsmasq'/>

    <!-- Assign static IPs and tags per MAC -->
    <dnsmasq:option value='dhcp-host=52:54:00:ab:cd:ef,192.168.122.61,harvester1,set:harvester_18'/>
    <dnsmasq:option value='dhcp-host=52:54:00:ab:cd:ea,192.168.122.62,harvester2,set:harvester_18_join'/>
    <dnsmasq:option value='dhcp-host=52:54:00:ab:cd:eb,192.168.122.63,harvester3,set:harvester_18_join'/>

    <!-- Detect when iPXE is already loaded (second DHCP request) -->
    <dnsmasq:option value='dhcp-userclass=set:ipxe,iPXE'/>

    <!-- Stage 1: UEFI (any host) → serve ipxe.efi via TFTP -->
    <dnsmasq:option value='dhcp-boot=tag:!ipxe,ipxe.efi'/>

    <!-- Stage 2: iPXE → serve per-role boot script URL -->
    <dnsmasq:option value='dhcp-boot=tag:harvester_18,tag:ipxe,http://192.168.122.1:6665/ipxe-create'/>
    <dnsmasq:option value='dhcp-boot=tag:harvester_18_join,tag:ipxe,http://192.168.122.1:6665/ipxe-join'/>
  </dnsmasq:options>
</network>
```

Apply changes:

```bash
virsh net-edit default
virsh net-destroy default && virsh net-start default
```

---

## iPXE Boot Script

The script is served by any HTTP server reachable at `192.168.122.1`. For more flexibility, a Node.js/Express server can generate the script dynamically from query parameters, e.g. `http://192.168.122.1:6665/ipxe-create?version=v1.5.1&ip=192.168.122.1`.

```bash
#!ipxe

dhcp

kernel http://192.168.122.1:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-vmlinuz-amd64 \
  ip=dhcp rd.net.dhcp.retry=30 rd.cos.disable rd.noverifyssl net.ifnames=1 \
  root=live:http://192.168.122.1:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-rootfs-amd64.squashfs \
  console=tty1 harvester.install.automatic=true harvester.install.skipchecks=true \
  harvester.install.config_url=http://192.168.122.1:6665/config-create.yaml
initrd http://192.168.122.1:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-initrd-amd64
boot
```

`dhcp` must be the first command. iPXE initializes its own network stack independently from UEFI — without it, all HTTP requests will fail with `Network unreachable`.

### config_url is optional

`harvester.install.config_url` is **not required**. All Harvester configuration can be passed directly as kernel boot parameters on the `kernel` line instead. This avoids hosting a separate YAML file entirely.

The following is **an example** of a fully inline `kernel` line:

```bash
#!ipxe

dhcp

kernel http://192.168.0.122:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-vmlinuz-amd64 \
  ip=dhcp rd.net.dhcp.retry=30 rd.cos.disable rd.noverifyssl net.ifnames=1 \
  root=live:http://192.168.0.122:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-rootfs-amd64.squashfs \
  console=tty1 \
  harvester.scheme_version=1 \
  harvester.token=t \
  harvester.os.hostname=harvester1 \
  harvester.os.password=p \
  harvester.os.dns_nameservers="8.8.8.8" \
  harvester.os.ntp_servers="0.suse.pool.ntp.org,1.suse.pool.ntp.org" \
  harvester.install.mode=create \
  harvester.install.management_interface.interfaces="name:enp1s0" \
  harvester.install.management_interface.default_route=true \
  harvester.install.management_interface.method=dhcp \
  harvester.install.management_interface.bond_options.mode="active-backup" \
  harvester.install.management_interface.bond_options.miimon="100" \
  harvester.install.device=/dev/vda \
  harvester.install.iso_url=http://192.168.0.122:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-amd64.iso \
  harvester.install.vip=192.168.122.100 \
  harvester.install.vip_mode=static \
  harvester.install.automatic=true
initrd http://192.168.0.122:6665/harvester/v1.8.0-rc6/harvester-v1.8.0-rc6-initrd-amd64
boot
```

All `harvester.*` keys are kernel boot parameters used by the Harvester installer.

---

## virt-install Command

```bash
sudo virt-install \
  --name test5 \
  --memory 12222 \
  --vcpus 10 \
  --boot uefi,loader=/usr/share/qemu/ovmf-x86_64-code.bin,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/qemu/ovmf-x86_64-vars.bin,hd,network \
  --machine q35 \
  --os-variant=slem5.3 \
  --disk /var/lib/libvirt/images/test5.qcow2,size=250,bus=virtio,format=qcow2,target=vda \
  --network network=default,model=virtio,mac=52:54:00:ab:cd:ef \
  --graphics vnc,listen=0.0.0.0,password=1234 \
  # --host-device=pci_0000_00_14_0 \ if you'd like to passthroug PCI device.
  --iommu model=intel,driver.intremap=on,driver.caching_mode=on \
  --features ioapic.driver=qemu \
  --check disk_size=off
```

Boot order is `hd,network`: on the first boot the disk is empty so UEFI falls through to network PXE. After installation, the disk boots directly without triggering PXE again.

> The `loader=` and `nvram.template=` flags are required. Without them OVMF returns `Access Denied` when trying to load the boot image.

---

## Common Issues

### 1. iPXE infinite reload loop

**Symptom**: iPXE loads, sends DHCP, downloads `ipxe.efi` again, repeats forever.

**Cause**: dnsmasq returns `ipxe.efi` for both Stage 1 (UEFI) and Stage 2 (iPXE) because there is no distinction between the two DHCP requests.

**Fix**: Add `dhcp-userclass=set:ipxe,iPXE` and use `tag:!ipxe` / `tag:ipxe` to split the two stages.

---

### 2. `Access Denied` when loading boot image

**Symptom**: OVMF shows `Access Denied` immediately after DHCP.

**Cause**: The `--boot` flag is missing `loader=` and `nvram.template=`. Without an explicit UEFI loader, OVMF cannot validate and load the image.

**Fix**: Always specify the full loader configuration in `--boot`.

---

### 3. `Network unreachable` when downloading kernel

**Symptom**: iPXE loads and fetches the boot script, but kernel download fails with `Network unreachable (https://ipxe.org/280a6090)`.

**Cause**: The boot script is missing the `dhcp` command. iPXE has its own network stack that must be initialized separately from UEFI.

**Fix**: Add `dhcp` as the first line of the boot script (after `#!ipxe`).

---

### 4. VM re-installs on every reboot

**Symptom**: After installation completes, the VM reboots and starts installing again.

**Cause**: Boot order is `network` before `hd`, so the VM always PXE boots.

**Fix**: Use `hd,network` in `--boot` so the disk is tried first. On first boot the disk is empty and UEFI falls through to PXE. After installation the disk boots directly.

To reinstall, destroy and recreate the VM:
```bash
virsh destroy test5
virsh undefine test5 --nvram
# re-run virt-install
```
