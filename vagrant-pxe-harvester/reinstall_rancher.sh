#!/bin/bash


MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

pushd $ROOTDIR
ansible-playbook ansible/reinstall_rancher.yml --extra-vars "@settings.yml"
popd
