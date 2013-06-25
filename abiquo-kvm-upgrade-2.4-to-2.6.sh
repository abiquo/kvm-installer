#!/bin/bash

LOG_FILE=abiquo-kvm-install.log
# Change this URL if you want to use a local repository:
MIRROR_URL=http://mirror.abiquo.com/abiquo/el6/

echo -n "Checking distribution... "
if [ -f "/etc/redhat-release" ]; then
        head -n1 "/etc/redhat-release"
    else
        echo "Unsupported distribution found." 
        exit 1
fi

echo -n "Checking previous versions... "
if [`abiquo-aim -v` != "AIM server version 1.5.2"]; then
        echo "AIM version does not match." 
        exit 1
    else 
	echo "OK."
fi

read -p "Upgrading Abiquo KVM, continue (y/n)? " ans

if [[ "${ans}" == 'y'  ||  "${ans}" == 'yes' ]]; then
    echo -n "Stopping AIM..."
    # Stop aim service
    service abiquo-aim stop >> $LOG_FILE 2>&1
    if [ $? == 0 ]; then
            echo "Done."
    else
            echo "Failed!"
    fi

    echo -n "Upgrading packages..."
    # Remove package locks from yum.conf
    sed -i /exclude=libvirt/d /etc/yum.conf >> $LOG_FILE 2>&1
    sed -i /abiquo/d /etc/yum.conf >> $LOG_FILE 2>&1
    #Install abiquo release
    rpm -Uvh $MIRROR_URL/abiquo-latest-release.noarch.rpm >> $LOG_FILE 2>&1
    # Upgrade packages
    yum clean all >> $LOG_FILE 2>&1
    yum -y install abiquo-cloud-node libvirt qemu-kvm >> $LOG_FILE 2>&1
    if [ $? == 0 ]; then
            echo "Done."
    else
            echo "Failed!"
    fi

    echo -n "Upgrading libvirt guests... "
    # Change machine model
    find /etc/libvirt/qemu/ABQ*.xml -exec sed -i s,pc-0.13,pc,g {} \; >> $LOG_FILE 2>&1
    # Delete BIOS loader
    find /etc/libvirt/qemu/ABQ*.xml -exec sed -i /loader/d {} \; >> $LOG_FILE 2>&1
    # Redefine all guests 
    find /etc/libvirt/qemu/ABQ*.xml -exec virsh define {} \; >> $LOG_FILE 2>&1
    echo "Done."

    echo -n "Starting aim... "
    # Start aim service
    service abiquo-aim start >> $LOG_FILE 2>&1
    if [ $? == 0 ]; then
            echo "Done."
    else
            echo "Failed!"
    fi
fi

