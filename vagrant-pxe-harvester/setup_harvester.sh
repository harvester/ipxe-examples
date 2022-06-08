#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))
REPROVISION=False
SETTINGS_FILE=settings.yml
PREV_SETTINGS_FILE=.settings.yml.orig

pushd $ROOTDIR
# check config change, 0 means no change, 2 means ENOENT (first time setup).
diff $SETTINGS_FILE $PREV_SETTINGS_FILE > /dev/null 2>&1
CONF_CHANGE=$?
# check vm status, if not running, vagrant up would do first time provision
vagrant status pxe_server |grep running |grep ^pxe_server > /dev/null 2>&1
VM_RUNNING=$?
# CONF_CHANGE: 1 means changed
# VM_RUNNING: 0 means running
if [[ $CONF_CHANGE == 1 && $VM_RUNNING == 0 ]]
then
	echo "Need re-provision."
	REPROVISION=True
fi
# backup this settings.yml this time
cp $SETTINGS_FILE $PREV_SETTINGS_FILE

ansible-playbook ansible/setup_harvester.yml  --extra-vars "@settings.yml" --extra-vars "provision=$REPROVISION"
ANSIBLE_PLAYBOOK_RESULT=$?
popd
exit $ANSIBLE_PLAYBOOK_RESULT
