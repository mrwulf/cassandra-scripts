#!/bin/sh
##################################################
# [build_raid.sh]                                #
#  Given a set of devices:                       #
#  - remove any volumes currenty using them      #
#  - partitions disks at a given percent of disk #
#    (for ssd over-provisioning)                 #
#  - build a raid volume using mdadm or lvm      #
#  - format it with ext4 or xfs                  #
#  - mount it                                    #
#  - display /etc/fstab mount options for disk   #
##################################################
DISK_PCT=100  # Default percentage of disk to partition
PROMPT_YES=   # If set, accept all prompts

usage() {
  ###################
  # Usage Statement #
  ###################
    PROG=$(basename $0)
    ERR_MSG="$*"
    [[ $ERR_MSG ]] && echo -e "\n ERROR: *** $ERR_MSG ***"
    cat << EOF

 Usage: $PROG
        -d <devices>          (list of devices; e.g, '/dev/sde /dev/sdd')
        -p <disk pct>         (percent of disk to partition; defaults to $DISK_PCT)
        -v <volume type>      (volume type; (lvm|mdadm))
        -f <fs type>          (file system type; (ext4|xfs)
        -m <mount point>      (volume mount point; e.g., '/ssd')
        -M <md device>        (mdadm device; e.g., '/dev/md3')
        -G <lvm vol group>    (LVM volume troup name; e.g., 'ssd_vg')
        -V <lvm logical vol>  (LVM logical volume name; e.g., 'ssd_volume')
        -y                    (accept yes on all prompts)

 Examples:

  To format SSD drives on /dev/sde and /dev/sdf with lvm, xfs and 90% (10% over-provisioning)

         $PROG -d '/dev/sde /dev/sdd' -p 90 -v lvm -f xfs -G ssd_vg -V ssd_lv -m /ssd

  To format SSD drives on /dev/sde and /dev/sdf with mdadm, ext4 and 90% (10% over-provisioning)

         $PROG -d '/dev/sde /dev/sdd' -p 90 -v mdadm -f ext4 -M /dev/md3 -m /ssd

EOF
    if [[ $ERR_MSG ]]; then
        exit 1
    else
        exit
    fi
}

errDie() {
  ##########################################################
  # Echo given string to stderr and exit with given status #
  ##########################################################
    MSG="\n ERROR: *** $1 ***\n"
    if [ $# -eq 2 ]; then
        STATUS=$2
    else
        STATUS=1
    fi
    echo -e "$MSG" 1>&2
    exit $STATUS
}

heading() {
  #############################
  # Print a formatted heading #
  #############################
    echo -e "\n[-- $@ --]\n"
}

indent() {
  ##########################################
  # Indent all lines of the called command #
  ##########################################
    "$@" 2>&1 | sed --unbuffered "s/^/  /"
    return ${PIPESTATUS[0]}
}

prompt() {
  ###################################
  # Issue prompt with given $MSG    #
  #  Return 0 if y/Y answer         #
  #  Return 1 for all other answers #
  ###################################
    MSG="$@"
    [[ $PROMPT_YES == yes ]] && return 0
    echo -ne "\n $MSG"
    read I
    if [[ $I =~ [yY] ]]; then
        return 0
    else
        return 1
    fi
}

###################
# Process Options #
###################
while getopts "d:p:v:f:m:M:G:V:y" options; do
  case $options in
     d ) DEVICES=$OPTARG;;
     p ) DISK_PCT=$OPTARG;;
     v ) VOL_TYPE=$OPTARG;;
     f ) FS_TYPE=$OPTARG;;
     m ) MOUNT_POINT=$OPTARG;;
     M ) MD_DEVICE=$OPTARG;;
     G ) LVM_VG=$OPTARG;;
     V ) LVM_LV=$OPTARG;;
     y ) PROMPT_YES=yes;;
     * ) usage;;
  esac
done

####################
# Validate Options #
####################
PROG_ARGS="$@"
[[ $PROG_ARGS ]]   || usage
[[ $DEVICES ]]     || usage "-d <devices> required"
[[ $DISK_PCT ]]    || usage "-p <format pct> required"
[[ $FS_TYPE ]]     || usage "-f <fs type> required"
[[ $VOL_TYPE ]]    || usage "-v <volume type> required"
[[ $MOUNT_POINT ]] || usage "-m <mount point> required"

if [[ $VOL_TYPE == mdadm ]]; then
    [[ $MD_DEVICE ]] || usage '-M <md device> required'
fi

if [[ $VOL_TYPE == lvm ]]; then
    [[ $LVM_VG ]] || usage '-G <lvm vol group> required'
    [[ $LVM_LV ]] || usage '-V <lvm logical vol> required'
fi

#############################
# Install RPMS if necessary #
#############################
if ! rpm -q gdisk > /dev/null 2>&1; then
    heading "Installing gdisk"
    indent yum -y install gdisk
fi
if [[ $FS_TYPE == xfs ]]; then
    if ! rpm -q xfsprogs > /dev/null 2>&1; then
        heading "Installing xfsprogs"
        indent yum -y install xfsprogs
    fi
fi

################################
# Verify all devices same type #
################################
MODELS=
heading "Checking disk models"
for DEV in $DEVICES; do
    MODEL=$(smartctl --all $DEV | grep ^Device.Model | cut -d':' -f2)
    MODELS="$MODEL\n$MODEL"
    indent echo "$DEV => $MODEL"
done
[[ $(echo -e "$MODELS" | sort -u | wc -l) -ne 1 ]] && errDie "All devices not the same type"

################
# Remove mount #
################
if cat /proc/mounts | awk '{print $2}' | grep -q ^${MOUNT_POINT}$; then
    prompt "$MOUNT_POINT currently mounted, drop it? " || errDie "Cannot proceed"
    heading "Umounting $MOUNT_POINT"
    indent umount -v $MOUNT_POINT || errDie "Unable to unmount $MOUNT_POINT"
fi

#################################
# Remove MD devices using disks #
#################################
CURRENT_MD_DEVS=$(lsblk -l $DEVICES | grep ^md | awk '{print $1}' | sort -u)
for MD_DEV in $CURRENT_MD_DEVS; do
    MD_DEV_PATH=/dev/$MD_DEV
    if [[ -e $MD_DEV_PATH ]]; then
        prompt "$MD_DEV_PATH using disks currently exists, drop it? " || errDie "Cannot proceed"
        heading "Stopping and removing $MD_DEV_PATH"
        indent mdadm --stop $MD_DEV_PATH
    fi
done

############################################################
# Remove LVM logical volumes and volume groups using disks #
############################################################
CURRENT_VGS=$(for D in $DEVICES; do pvdisplay | grep -A1 $D | grep "VG Name" | awk '{print $3}'; done | sort -u)
for VG in $CURRENT_VGS; do
    CURRENT_LV_DEV_PATHS=$(lvdisplay | grep "LV Path" | grep -B1 $VG | awk '{print $3}' | sort -u)
    for LV_DEV_PATH in $CURRENT_LV_DEV_PATHS; do
        #####################
        # Remove LVM volume #
        #####################
        if [[ -e $LV_DEV_PATH ]]; then
            prompt "LVM logical volume $LV_DEV_PATH using disks currently exists, drop it? " || errDie "Cannot proceed"
            heading "Removing LVM logical volume $LV_DEV_PATH"
            indent lvremove -y $LV_DEV_PATH
        fi
    done

    ###########################
    # Remove LVM volume group #
    ###########################
    if vgdisplay | awk '{print $3}' | grep -q ^${VG}$; then
        prompt "LVM volume group $VG currently exists, drop it? " || errDie "Cannot proceed"
        heading "Removing LVM volume group $VG"
        indent vgchange -a n $VG
        indent vgremove -y $VG
    fi
done

###################
# Partition Disks #
###################
DISK_CNT=0
DEV_PARTS=
for DEV in $DEVICES; do
    DISK_CNT=$((DISK_CNT+1))
    heading "Zeroing out $DEV"
    indent sgdisk -Z $DEV
    indent dd if=/dev/zero of=$DEV bs=1M count=50

    TOTAL_SECTORS=$(gdisk -l $DEV | grep ^Disk.*sectors | awk '{print $3}')
    PART_SECTORS=$((TOTAL_SECTORS*DISK_PCT/100))
    heading "Partitioning $DEV to $PART_SECTORS of $TOTAL_SECTORS sectors"
    indent sgdisk -og $DEV
    indent sgdisk -n 1:0:$PART_SECTORS -c 1:"SSD drive $DISK_CNT" $DEV
    indent gdisk -l $DEV
    echo
    DEV_PARTS="$DEV_PARTS ${DEV}1"
done

#################
# Create Volume #
#################
if [[ $VOL_TYPE == mdadm ]]; then
    DEV_PATH=$MD_DEVICE
    heading "Creating RAID-0 volume $DEV_PATH using $DEV_PARTS"
    indent mdadm --create $DEV_PATH --chunk=64 --metadata=1.2 --raid-devices=$DISK_CNT --level=0 $DEV_PARTS || errDie "Unable to create raid volume $DEV_PATH"
elif [[ $VOL_TYPE == lvm ]]; then
    DEV_PATH=/dev/$LVM_VG/$LVM_LV
    heading "Creating LVM volume $LVM_LV using $DEV_PARTS"
    indent vgcreate $LVM_VG $DEV_PARTS || errDie "Unable to create $LVM_VG"
    indent lvcreate -i${DISK_CNT} -I64 -l 100%FREE -n $LVM_LV $LVM_VG $DEV_PARTS || errDie "Unable to create $LVM_VM"
fi

######################
# Create File System #
######################
heading "Creating $MOUNT_POINT file system with $FS_TYPE"
if [[ $FS_TYPE == ext4 ]]; then
    indent mkfs.ext4 -m 0 $DEV_PATH
elif [[ $FS_TYPE == xfs ]]; then
    if ! rpm -q xfsprogs > /dev/null; then
        heading "Installing xfsprogs"
        indent yum -y install xfsprogs
    fi
    indent mkfs.xfs -b size=4096 -d su=262144 -d sw=$DISK_CNT $DEV_PATH
else
    echo -e "\nError: unknown file system type ($FS_TYPE)!"
    exit 1
fi

##############
# Mount disk #
##############
if [[ ! -e $MOUNT_POINT ]]; then
    heading "Making directory $MOUNT_POINT"
    indent mkdir -p $MOUNT_POINT
fi

heading "Mounting $DEV_PATH to $MOUNT_POINT"
indent mount -t $FS_TYPE $DEV_PATH $MOUNT_POINT
indent mount | grep $MOUNT_POINT

##################
# Show df output #
##################
indent df -h | grep $MOUNT_POINT

######################################
# Provide /etc/fstab config for disk #
######################################
heading "Add the following to /etc/fstab"
UUID=$(blkid $DEV_PATH -o value | head -1)
echo "UUID=$UUID $MOUNT_POINT                    $FS_TYPE    rw,noatime  1 2"

