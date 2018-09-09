# Create spinnaker iam role + iam role to assume for spinnaker to create

# Allow ec2 instance to assume this role
data "aws_iam_policy_document" "spinnaker_managed_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "application-autoscaling.amazonaws.com",
        "ecs.amazonaws.com",
      ]
    }

    # Allow some spinnaker role to assume it
    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.spinnaker.arn}"]
    }
  }
}

# Create the spinnaker managed role
resource "aws_iam_role" "spinnaker_managed" {
  name               = "${var.spinnaker_managed_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.spinnaker_managed_assume_role_policy.json}"
}

# Create instance profile for the spinnaker role
resource "aws_iam_instance_profile" "spinnaker_managed" {
  name = "${aws_iam_role.spinnaker_managed.name}"
  role = "${aws_iam_role.spinnaker_managed.name}"
}

# Allow spinnaker to read/write to the s3 bucket, and assume other roles
data "aws_iam_policy_document" "spinnaker_managed" {
  statement {
    actions = [
      "iam:PassRole",
      "ec2:Describe*",
      "ec2:List*",
      "ec2:RegisterImage",
      "ec2:ModifyImageAttribute",
      "ec2:ResetImageAttribute",
      "ec2:CreateTags",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ecs:*",
      "autoscaling:Describe*",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:PutScalingPolicy",
      "autoscaling:DeletePolicy",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:ResumeProcesses",
      "autoscaling:SuspendProcesses",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DeleteTags",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "cloudwatch:Describe*",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:EnableAlarmActions",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:PutMetricData",
      "cloudwatch:SetAlarmState",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:ListMetrics",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "spinnaker_managed" {
  name   = "spinnaker_managed"
  role   = "${aws_iam_role.spinnaker_managed.id}"
  policy = "${data.aws_iam_policy_document.spinnaker_managed.json}"
}
