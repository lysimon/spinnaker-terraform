# Create all the resources for ec2 spinnaker configuration

# Security group, to be able to access it from your ip address
resource "aws_security_group" "spinnaker" {
  name        = "spinnaker_security_group"
  description = "Allow communication to spinnaker"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = "${var.allowed_cidr}"
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "TCP"
    cidr_blocks = "${var.allowed_cidr}"
  }

  # Allow all egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create key pair, so that spinnaker instance contain it
resource "aws_key_pair" "spinnaker" {
  key_name   = "spinnaker-key"
  public_key = "${var.spinnaker_public_key}"
}

# Create the spinnaker ec2 instance from ubuntu 14.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Add the spinnaker configuration file in this s3 bucket, to the root path
data "template_file" "spinnaker_userdata" {
  template = "${file("${path.module}/spinnaker_userdata.sh.tpl")}"

  vars {
    s3_spinnaker_bucket_name = "${var.s3_spinnaker_bucket_name}"
    region                   = "${var.region}"
  }
}

resource "aws_launch_configuration" "spinnaker" {
  name_prefix = "spinnaker-"
  key_name    = "${aws_key_pair.spinnaker.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.spinnaker.arn}"

  security_groups = [
    "${aws_security_group.spinnaker.id}",
  ]

  user_data = "${data.template_file.spinnaker_userdata.rendered}"

  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "m4.xlarge"

  # We can set a high spot price, it will never go above this one
  # spot_price = "3"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "spinnaker" {
  name_prefix = "spinnaker-"
  max_size    = 1
  min_size    = 0

  # Create desired capacity and ignore change due to night
  desired_capacity = 1

  # Spinnaker should be able to mount the volume and read its installation file
  depends_on = [
  "aws_ebs_volume.spinnaker_redis",
  "aws_iam_role_policy.spinnaker_s3",
  "aws_s3_bucket_object.ubuntu_spinnaker_installation",
  ]

  lifecycle {
    ignore_changes        = ["desired_capacity"]
    create_before_destroy = false
  }

  launch_configuration = "${aws_launch_configuration.spinnaker.name}"
  availability_zones   = ["${var.availability_zone}"]

  tags = [
    {
      key                 = "Name"
      value               = "${var.spinnaker_name}"
      propagate_at_launch = true
    },
    {
      key                 = "Team"
      value               = "${var.team}"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]
}

# Create an ebs volume for redis
resource "aws_ebs_volume" "spinnaker_redis" {
  availability_zone = "${var.availability_zone}"
  size              = 10

  tags {
    Name        = "spinnaker_redis"
    Environment = "${var.environment}"
    Team        = "${var.team}"
  }
}

# Start at 7:30 in the morning
resource "aws_autoscaling_schedule" "spinnaker_start" {
  scheduled_action_name  = "spinnaker_start"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "30 5 * * mon,tue,wed,thu,fri"
  autoscaling_group_name = "${aws_autoscaling_group.spinnaker.name}"
}

# Shutdown at 8:30 pm
resource "aws_autoscaling_schedule" "spinnaker_stop" {
  scheduled_action_name  = "spinnaker_stop"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  recurrence             = "30 18 * * mon,tue,wed,thu,fri"
  autoscaling_group_name = "${aws_autoscaling_group.spinnaker.name}"
}
