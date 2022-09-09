#!/usr/bin/env bash

main () {
    echo -e "\n...running checks...\n";

    if ! command -v virsh --version &> /dev/null
    then 
        echo "coludn't find virsh - please install"
    else
        default_network_search_result=$(virsh net-list --persistent --autostart --name | grep -e "default")
        if [ "$default_network_search_result" = "default" ]; then
            echo "a network named 'default' is present, with autostart and persistence, looks great, continuing checks..."
        else
            echo "we must have a network named 'default' that exists with persistence and autostart"
            echo -e "something like: \n"
            cat << EOF
                <network>
                <name>default</name>
                <uuid>9521fb90-03f5-4ebb-bb62-afb50bc77f2d</uuid>
                <forward mode="nat">
                    <nat>
                    <port start="1024" end="65535"/>
                    </nat>
                </forward>
                <bridge name="virbr0" stp="on" delay="0"/>
                <mac address="52:54:00:d9:58:f0"/>
                <ip address="192.168.122.1" netmask="255.255.255.0">
                    <dhcp>
                    <range start="192.168.122.2" end="192.168.122.254"/>
                    </dhcp>
                </ip>
                </network>
EOF
        fi
    fi

    if ! command -v sshpass &> /dev/null
    then
        ## todo: make it dynamically install based on distros
        echo "sshpass couldn't be found - please install at version 1.0.9 or higher";
    else
        echo "sshpass installed running version check...";
        sshpass_current_version=$(sshpass -V | cut -d ' ' -f 2 | head -1);
        requiredver="1.0.9"
        if [ "$(printf '%s\n' "$requiredver" "$sshpass_current_version" | sort -V | head -n1)" = "$requiredver" ]; then 
            echo "Greater than or equal to ${requiredver} - we're going to continue, since this should be fine... for sshpass"
        else
            echo "Less than ${requiredver} for sshpass"
        fi
    fi 

    # ansible galaxy can't be installed without ansible
    if ! command -v ansible-galaxy &> /dev/null
    then
        ## todo: make it dynamically install based on distros
        echo "ansible-galaxy could not be found - please install at version 2.13.0 or higher, you'll need ansible as a dependency";
    else
        ## check the version of ansible-galaxy is at the same or higher version
        echo "ansible-galaxy is isntalled, running version check..."
        check_ansible_galaxy_version=$(ansible-galaxy --version | tr -s ' ' | cut -d ' ' -f 3 | awk '{ printf $0 }' | cut -d ']' -f 1);
        requiredver="2.13.0"
        if [ "$(printf '%s\n' "$requiredver" "$check_ansible_galaxy_version" | sort -V | head -n1)" = "$requiredver" ]; then 
            echo "Greater than or equal to ${requiredver} - we're going to continue, since this should be fine... for ansible/ansible-galaxy"
        else
            echo "Less than ${requiredver} for ansible / ansible-galaxy"
        fi
        ## check ansible-galaxy has the community.general installed and at a same or higher version
        result=$(ansible-galaxy collection list | awk '{ printf $0 }' | tr -d '[=-=]' | grep -Eoh "community.general [0-9].[0-9].[0-9]");
        if test -z "$result"
        then
            echo -e "\nwe need to install community.general... please install: \n  ansible-galaxy collection install community.general; \n at a version 5.4.0 or higher \n";
        else
            echo -e "\ncommunity.general is installed, checking version...\n";
            currentver=$(echo $result | tr -s ' ' | cut -d ' ' -f 2);
            requiredver="5.4.0"
            if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then 
                echo "Greater than or equal to ${requiredver} - we're going to continue, since this should be fine... for community.general"
            else
                echo "Less than ${requiredver} community.general"
            fi
        fi
    fi

    if ! command -v vagrant &> /dev/null
    then
        # todo: make it dynamically install vagrant on distro
        echo "please install vagrant at version: 2.2.19 or higher"
    else
        current_version_vagrant_libvirt=$(vagrant plugin list | grep -Eoh "vagrant-libvirt \([0-9].[0-9].[0-9], system\)" | tr -d '[=(=]' | tr -d '[=,=]' |  cut -d ' ' -f 2);
        requiredver="0.7.0"
        if [ "$(printf '%s\n' "$requiredver" "$current_version_vagrant_libvirt" | sort -V | head -n1)" = "$requiredver" ]; then 
            echo "Greater than or equal to ${requiredver} - we're going to continue, since this should be fine... for vagrant's vagrant-libvirt plugin"
        else
            echo "Less than ${requiredver} for vagrant's vagrant-libvirt plugin"
        fi
    fi

    echo -e "\n...finished checks...\n";
    exit 0
}

echo -e "\n ...starting... \n"

main