#!/bin/bash -ex
mkdir -p /etc/skypicker
echo 'bastion'>/etc/skypicker/InstanceType
echo 'prod'>/etc/skypicker/Stage
echo 'master'>/etc/skypicker/AnsibleBranch
sudo mkdir -p /etc/ansible/facts.d
echo '[default]'>/etc/ansible/facts.d/prefs.fact
echo ''>>/etc/ansible/facts.d/prefs.fact
