#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

pushd $ROOTDIR
if grep -Fxq "overall_debug: true" $ROOTDIR/settings.yml
then
    echo "vagrant-pxe-harvester, debug enabled..."
    ANSIBLE_VERBOSITY=7 ansible-playbook ansible/setup_harvester.yml --extra-vars "@settings.yml"
else
    ansible-playbook ansible/setup_harvester.yml --extra-vars "@settings.yml"
fi
ANSIBLE_PLAYBOOK_RESULT=$?
popd
exit $ANSIBLE_PLAYBOOK_RESULT
