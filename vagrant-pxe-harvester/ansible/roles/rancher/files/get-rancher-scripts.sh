# vim get-rancher-scripts
#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'This requires you to pass a version for the url like "v2.6.5"'
    exit 1
fi
wget https://github.com/rancher/rancher/releases/download/$1/rancher-images.txt
wget https://github.com/rancher/rancher/releases/download/$1/rancher-load-images.sh
wget https://github.com/rancher/rancher/releases/download/$1/rancher-save-images.sh
