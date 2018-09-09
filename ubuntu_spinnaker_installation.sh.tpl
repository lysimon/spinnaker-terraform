#!/bin/bash

# Fail on first error, so that spinnaker does not start if any failure occurs
set -ex
# run on ubuntu 14.04 in order to have correct logging folders

# Optional, mount spinnaker redis volume to /var/lib/redis for data persistency
instanceid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
~/.local/bin/aws ec2 attach-volume --region ${region} --volume-id ${redis_volume_id} --instance-id `echo $instanceid` --device /dev/xvdr
# Create redis directory
useradd redis
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
sleep 10
# Try to mount it, if not possible, clear it and mount it
if mount /dev/xvdr /var/lib/redis ; then
    echo "Command succeeded"
else
    echo "Command failed, reseting redis by executing mkfs command"
    mkfs -t ext4 /dev/xvdr
    mount /dev/xvdr /var/lib/redis
fi


# Install halyard with force yes
useradd halyard
curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh
bash InstallHalyard.sh --user halyard -y

# purge halyard, not required because we start with fresh instance
#rm -Rf ~/.hal

# CONFIGURE ALL AWS ACCOUNTS HERE:
echo "got path $PATH"
export PATH=/usr/local/bin:$PATH
echo "got new path $PATH"

# Configure front50 storage
hal config storage s3 edit --bucket ${s3_spinnaker_bucket_name} --root-folder ${s3_spinnaker_front50_folder_name}
hal config storage edit --type s3


# configure accounts:
hal config provider aws account add aws-account-ec2 \
                    --account-id ${account_id} \
                    --assume-role role/spinnaker_managed \
                    --regions ${region}

# Enabling aws
hal config provider aws enable

# ecs
hal config provider ecs account add aws-account-ecs --aws-account aws-account-ec2
hal config provider ecs enable

# Configure authentication
# Does not work due to https://github.com/spinnaker/spinnaker/issues/3154
# see https://www.spinnaker.io/setup/security/authorization/github-teams/
#hal config security authz github edit \
#    --accessToken ${spinnaker_fiat_github_token} \
#    --organization ${spinnaker_fiat_github_org} \
#    --baseUrl ${spinnaker_fiat_github_base_url}

#hal config security authz edit --type github
#hal config security authz enable


hal config version edit --version ${spinnaker_version}

hal config deploy edit --type localdebian

# Install spin as well for auto generating pipelines
# hal spin install

# deploy with the current configuration
sudo hal deploy apply

# Install spin for pipelines configuration, todo, use hal but currently not working
# https://www.spinnaker.io/guides/spin/cli/#install-and-configure-spin-cli
curl -LO https://storage.googleapis.com/spinnaker-artifacts/spin/$(curl -s https://storage.googleapis.com/spinnaker-artifacts/spin/latest)/linux/amd64/spin
chmod +x spin
sudo mv spin /usr/local/bin/spin

# Sleeping for 2 min to let time for spinnaker to start
# We can then execute all cron job we want to update the pipelines / applications
sleep 120
