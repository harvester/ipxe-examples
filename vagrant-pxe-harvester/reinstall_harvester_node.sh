#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

USAGE="${0}: <node number>

Where:

  <node number>: node to re-install. Node number starts with zero (0). For
                 example, if you want to re-install the 3rd node, the node
                 number given should be 2.
"

if [ $# -ne 1 ] ; then
  echo "$USAGE"
  exit 1
fi

NODE_NUMBER=$1
NODE_NAME="harvester-node-${NODE_NUMBER}"
TOTAL_NODES_STR=`grep harvester_cluster_nodes: settings.yml`

# check to make sure the node has not been created
NOT_CREATED=`vagrant status | grep "^${NODE_NAME}" | grep "not created" || true`

if [ "${NOT_CREATED}" == "" ] ; then
  echo "${NODE_NAME} already created or exceeds defined size (${TOTAL_NODES_STR})."
  exit 1
fi

pushd $ROOTDIR
ansible-playbook ansible/reinstall_harvester_node.yml --extra-vars "@settings.yml" --extra-vars "node_number=${NODE_NUMBER}"
popd
