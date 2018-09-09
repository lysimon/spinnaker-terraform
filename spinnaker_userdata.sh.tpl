#!/bin/bash

set -ex

# ssh -L 9000:localhost:9000 -L 8084:localhost:8084 -L 8087:localhost:8087 ubuntu@34.244.243.191
# Update dependencies
apt-get update
apt-get install python3 -y

# Install aws-cli with pip according to https://docs.aws.amazon.com/cli/latest/userguide/installing.H3gPatvhgzibmIwCtjFpsl4eic7NjFiHmyKTkub3kmgnDru7
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip3 install awscli --upgrade --user

# Download installation script from s3
~/.local/bin/aws s3 --region ${region} cp s3://${s3_spinnaker_bucket_name}/ubuntu_spinnaker_installation.sh /tmp/ubuntu_spinnaker_installation.sh

# Make it executable
chmod +x /tmp/ubuntu_spinnaker_installation.sh
# Execute it
/tmp/ubuntu_spinnaker_installation.sh
