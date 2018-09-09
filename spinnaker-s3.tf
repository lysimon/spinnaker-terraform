# Creating the bucket for spinnaker configuration + spinnaker script inside

# Spinnaker will be allowed to write to this s3 bucket
resource "aws_s3_bucket" "spinnaker_bucket" {
  bucket = "${var.s3_spinnaker_bucket_name}"
  acl    = "private"

  force_destroy = "true"

  # Feel free to add more tags if needed
  tags {
    Name        = "${var.s3_spinnaker_bucket_name}"
    Team        = "${var.team}"
    Environment = "${var.environment}"
  }
}

# Add the spinnaker configuration file in this s3 bucket, to the root path
data "template_file" "spinnaker_installation" {
  template = "${file("${path.module}/ubuntu_spinnaker_installation.sh.tpl")}"

  vars {
    s3_spinnaker_bucket_name         = "${var.s3_spinnaker_bucket_name}"
    s3_spinnaker_front50_folder_name = "${var.s3_spinnaker_front50_folder_name}"
    account_id                       = "${data.aws_caller_identity.current.account_id}"
    spinnaker_version                = "${var.spinnaker_version}"
    region                           = "${var.region}"
    redis_volume_id                  = "${aws_ebs_volume.spinnaker_redis.id}"
    spinnaker_fiat_github_org        = "${var.spinnaker_fiat_github_org}"
    spinnaker_fiat_github_token      = "${var.spinnaker_fiat_github_token}"
    spinnaker_fiat_github_base_url   = "${var.spinnaker_fiat_github_base_url}"
  }
}

# TODO add encryption
resource "aws_s3_bucket_object" "ubuntu_spinnaker_installation" {
  bucket  = "${aws_s3_bucket.spinnaker_bucket.bucket}"
  key     = "ubuntu_spinnaker_installation.sh"
  content = "${data.template_file.spinnaker_installation.rendered}"
}
