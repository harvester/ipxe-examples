#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

pushd $ROOTDIR
ansible-playbook ansible/setup_harvester.yml --extra-vars "@settings.yml"
popd

