# Create spinnaker iam role + iam role to assume for spinnaker to create

# Allow ec2 instance to assume this role
data "aws_iam_policy_document" "spinnaker_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create the spinnaker role
resource "aws_iam_role" "spinnaker" {
  name               = "${var.spinnaker_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.spinnaker_assume_role_policy.json}"
}

# Create instance profile for the spinnaker role
resource "aws_iam_instance_profile" "spinnaker" {
  name = "${aws_iam_role.spinnaker.name}"
  role = "${aws_iam_role.spinnaker.name}"
}

# Allow spinnaker to assume other roles for release
data "aws_iam_policy_document" "spinnaker_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "spinnaker_assume_role" {
  name   = "spinnaker_assume_role"
  role   = "${aws_iam_role.spinnaker.id}"
  policy = "${data.aws_iam_policy_document.spinnaker_assume_role.json}"
}

# Allow spinnaker to read/write into the s3 bucket
data "aws_iam_policy_document" "spinnaker_s3" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:Get*",
      "s3:List*",
      "s3:PutObject*",
    ]

    resources = [
      "${aws_s3_bucket.spinnaker_bucket.arn}",
      "${aws_s3_bucket.spinnaker_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "spinnaker_s3" {
  name   = "spinnaker_s3"
  role   = "${aws_iam_role.spinnaker.id}"
  policy = "${data.aws_iam_policy_document.spinnaker_s3.json}"
}

# Allow spinnaker to read ec2 instance, will not start otherwise
data "aws_iam_policy_document" "spinnaker_readonly" {
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:List*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "spinnaker_readonly" {
  name   = "spinnaker_readonly"
  role   = "${aws_iam_role.spinnaker.id}"
  policy = "${data.aws_iam_policy_document.spinnaker_readonly.json}"
}

# Allow spinnaker to attach its ebs volume for redis
data "aws_iam_policy_document" "spinnaker_attach_volume" {
  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = [
      "${aws_ebs_volume.spinnaker_redis.arn}",
    ]
  }

  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]

    resources = [
      "arn:aws:ec2:*:*:instance/*",
    ]

    condition = {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"

      values = [
        "${var.spinnaker_name}",
      ]
    }
  }
}

resource "aws_iam_role_policy" "spinnaker_attach_volume" {
  name   = "spinnaker_attach_volume"
  role   = "${aws_iam_role.spinnaker.id}"
  policy = "${data.aws_iam_policy_document.spinnaker_attach_volume.json}"
}
