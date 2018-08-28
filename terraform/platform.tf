provider "aws" {
  version    = ">= 1.31.0"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_vpc" "main" {
  tags {
    Name = "nimahend-Datacenter VPC"
  }

  cidr_block           = "${var.cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "dcsubnet_public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet("${var.cidr_block}", 8, 1)}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_availability_zones[0]}"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "az_subnets_public" {
  count                   = "${length(var.aws_availability_zones)}"
  cidr_block              = "${cidrsubnet(var.cidr_block, 8, count.index + 20)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "dcgateway" {
  tags {
    Name = "nimahend-DC Internet gateway"
  }

  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public_subnet_route_table" {
  tags {
    Name = "nimahend-Public subnet Internet-Gateway route"
  }

  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dcgateway.id}"
  }
}

resource "aws_route_table_association" "multiaz_public" {
  count          = "${length(var.aws_availability_zones)}"
  subnet_id      = "${element(aws_subnet.az_subnets_public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_subnet_route_table.id}"
}

resource "aws_route_table_association" "subnet_public" {
  subnet_id      = "${aws_subnet.dcsubnet_public.id}"
  route_table_id = "${aws_route_table.public_subnet_route_table.id}"
}

module "devops" {
  source          = "./devops"
  ecsami          = "${lookup(var.ecs_amis,var.aws_region)}"
  key_name        = "${var.key_name}"
  aws_subnet_id   = "${aws_subnet.dcsubnet_public.id}"
  aws_vpc_id      = "${aws_vpc.main.id}"
  multiaz_subnets = ["${aws_subnet.az_subnets_public.*.id}"]
}
