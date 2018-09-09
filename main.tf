variable "aws_region" {
  type    = "string"
}

variable "availability_zone" {
  type    = "string"
}

# Configure aws provider here
provider "aws" {
  region = "${var.aws_region}"
}

# s3 bucket name used for front50 in spinnaker
# We will also store the starter script of the ASG there
variable "s3_spinnaker_bucket_name" {
  type = "string"
}

variable "s3_spinnaker_front50_folder_name" {
  default = "front50"
  type    = "string"
}

variable "spinnaker_version" {
  default = "1.9.2"
  type    = "string"
}

variable "spinnaker_name" {
  default = "spinnaker"
  type    = "string"
}

variable "spinnaker_public_key" {
  type = "string"
}

variable "spinnaker_role_name" {
  default = "spinnaker"
  type    = "string"
}

variable "spinnaker_managed_role_name" {
  default = "spinnaker_managed"
  type    = "string"
}

# see https://www.spinnaker.io/setup/security/authorization/github-teams/
variable "spinnaker_fiat_github_token" {
  default = "spinnaker_managed"
  type    = "string"
}

variable "spinnaker_fiat_github_org" {
  default = "spinnaker_managed"
  type    = "string"
}

variable "spinnaker_fiat_github_base_url" {
  default = "https://api.github.com"
  type    = "string"
}

variable "environment" {
  default = "production"
  type    = "string"
}

variable "team" {
  default = "data-team"
  type    = "string"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "allowed_cidr" {
  default = []
  type    = "list"
}

# Get caller identity for iam role and spinnaker configuration
data "aws_caller_identity" "current" {}
