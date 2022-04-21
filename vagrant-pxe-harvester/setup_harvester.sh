#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

pushd $ROOTDIR
ansible-playbook ansible/setup_harvester.yml --extra-vars "@settings.yml" && ansible-playbook ansible/prepare_harvester_nodes.yml --extra-vars "@settings.yml" -i inventory
ANSIBLE_PLAYBOOK_RESULT=$?
popd
exit $ANSIBLE_PLAYBOOK_RESULT
