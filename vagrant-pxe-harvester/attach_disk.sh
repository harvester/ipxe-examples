#!/bin/bash
# The script creates a QEMU image and attaches it to a Vagrant (libvirt) VM.
#
# What the script does:
# (1) It attaches a virtio-scsi controller to a domain if the domain doesn't have a controller yet.
# (2) Create a qcow2 file under $DISKS_DIR and attach it to the provided domain.
#
# Although we could not detect the next device automatically, now it is easy to use.
#

USAGE="
Usage: ${0} <Node#> <DiskSizeGB> <TargetDevice> [WWN] [-v Vendor, --vendor Vendor]

Positional Args:
  * Node#: harvester-node-#, e.g. 0, 1, 2
  * DiskSizeGB: e.g. 16
  * TargetDevice: e.g. sda
  * WWN: Optional, will generate randomly if not specified. e.g. 0x5000c500158817a9

Keyword Args:
  * -v Vendor, --vendor Vendor: Provide <vendor>
  * -d, --dryrun: Dry run, print the variables and exit without executing the commands
  * -h, --help: Show this help message and exit

Example:
  * ./attach_disk.sh 0 16 sda -> Plug a 16GB disk (random WWN, w/o vendor) to node-0
  * ./attach_disk.sh 0 16 sda 0x5000c500158817a9 -> Plug a 16GB disk (specified WWN, w/o vendor) to node-0
  * ./attach_disk.sh 0 16 sda --vendor longhorn -> Plug a 16GB disk (random WWN, w vendor) to node-0
"

if [[ $# -lt 3 ]]; then
    echo -e "$USAGE"
    exit 1
fi


# parsing getopt
if ! OPTIONS=$(getopt -o v:hd --long vendor:,help,dryrun --name "$0" -- "$@"); then
    echo "Terminating..." >&2
    exit 1
fi

DRYRUN=false
eval set -- "$OPTIONS"
while true; do
    case "$1" in
        -v | --vendor)
            VENDOR="$2"
            shift 2
            ;;
        -h | --help)
            echo -e "$USAGE"
            shift
            exit 0
            ;;
        -d | --dryrun)
            DRYRUN=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "$USAGE"
            exit 1
            ;;
    esac
done


# initialize variables
TARGET_VM=$(basename "$PWD")_harvester-node-$1
DISK_SIZE=$2
TARGET_DEVICE=$3
DISK_WWN=$4
DISK_NAME=$TARGET_VM-$TARGET_DEVICE

DISK1_PATH=$(virsh domblklist $TARGET_VM | grep vda | awk '{print $2}')
if [ ! -f "$DISK1_PATH" ]; then
    echo "Invalid disk image path: $DISK1_PATH" >&2
    exit 1
fi
DISKS_DIR=$(dirname "$DISK1_PATH")

if [ -z "${DISK_WWN}" ]; then
    DISK_WWN=0x5000c50015$(date +%s | sha512sum | head -c 6)
    echo "WWN not specified; using a random one: ${DISK_WWN}"
fi


if ${DRYRUN}; then
    echo --- Target VM
    echo TARGET_VM: $TARGET_VM
    echo DISKS_DIR: $DISKS_DIR
    echo
    echo --- New Disk
    echo TARGET_DEVICE: $TARGET_DEVICE
    echo DISK_SIZE: $DISK_SIZE
    echo DISK_WWN: $DISK_WWN
    echo DISK_NAME: $DISK_NAME
    echo VENDOR: $VENDOR
    echo
    echo --- getopt
    echo "Remaining getopt arguments: $*"
    exit
fi


# create disk image
mkdir -p $DISKS_DIR
FILE=$DISKS_DIR/$DISK_NAME.qcow2
qemu-img create -f qcow2 $FILE "${DISK_SIZE}"g


CONTROLLER_XML=controller.xml
cat > $CONTROLLER_XML << EOF
    <controller type='scsi' model='virtio-scsi' index='0'/>
EOF
trap 'rm "$CONTROLLER_XML"' EXIT

# attach virtio-scsi controller, it's more robust for hotplugging
if ! virsh dumpxml $TARGET_VM | grep -q 'virtio-scsi'; then
  echo "Attach virtio-scsi controller to $TARGET_VM"
  virsh attach-device --domain $TARGET_VM --file $CONTROLLER_XML --live
fi

# attach device
XML_FILE=$DISKS_DIR/$DISK_NAME.xml

cat /dev/null > $XML_FILE
cat > $XML_FILE <<EOF
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$FILE'/>
      <target dev='$TARGET_DEVICE' bus='scsi'/>
      <wwn>$DISK_WWN</wwn>
EOF

[ -n "$VENDOR" ] && echo "      <vendor>$VENDOR</vendor>" >> $XML_FILE

echo "    </disk>" >> $XML_FILE

virsh attach-device --domain $TARGET_VM --file $XML_FILE --live
