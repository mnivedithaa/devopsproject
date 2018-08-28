variable "aws_region" {}

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "ecs_amis" {
  type = "map"

  default = {
    us-east-2      = "ami-67ab9e02"
    us-east-1      = "ami-5e414e24"
    us-west-2      = "ami-10ed6968"
    us-west-1      = "ami-00898660"
    eu-west-3      = "ami-6fa21412"
    eu-west-2      = "ami-42a64325"
    eu-west-1      = "ami-880d64f1"
    eu-central-1   = "ami-63cbae0c"
    ap-northeast-2 = "ami-0acc6e64"
    ap-northeast-1 = "ami-e3166185"
    ap-southeast-2 = "ami-36867d54"
    ap-southeast-1 = "ami-66c98f1a"
    ca-central-1   = "ami-4b9c182f"
    ap-south-1     = "ami-ca8ad9a5"
    sa-east-1      = "ami-69f7b805"
  }
}

variable "key_name" {}

variable "aws_availability_zones" {
  type = "list"
}

variable "cidr_block" {}
