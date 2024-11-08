#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

pushd $ROOTDIR
ansible-playbook -v ansible/setup_harvester.yml --extra-vars "@settings.yml"
ANSIBLE_PLAYBOOK_RESULT=$?
popd
exit $ANSIBLE_PLAYBOOK_RESULT
