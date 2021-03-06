provider "aws" {
    region = "${var.region}"
    profile = "${var.aws_profile}"
    alias = "vpc"
}

resource "aws_vpc" "mod" {
  provider = "aws.vpc"
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support = "${var.enable_dns_support}"
  tags { Name = "${var.name}" }
}

resource "aws_internet_gateway" "mod" {
  provider = "aws.vpc"
  vpc_id = "${aws_vpc.mod.id}"
}

resource "aws_eip" "nat" {
  provider = "aws.vpc"
  vpc = true
  count = "${length(compact(split(",", var.private_subnets)))}"
}

resource "aws_nat_gateway" "mod" {
  provider = "aws.vpc"
  count = "${length(compact(split(",", var.public_subnets)))}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.mod"]
}

resource "aws_route_table" "public" {
  provider = "aws.vpc"
  vpc_id = "${aws_vpc.mod.id}"
  tags { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet_gateway" {
  provider = "aws.vpc"
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.mod.id}"
}

resource "aws_route" "private_nat_gateway" {
  provider = "aws.vpc"
  count = "${length(compact(split(",", var.private_subnets)))}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.mod.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  provider = "aws.vpc"
  vpc_id = "${aws_vpc.mod.id}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "private" {
  provider = "aws.vpc"
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.private_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "public" {
  provider = "aws.vpc"
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.public_subnets)))}"
  tags { Name = "${var.name}-public" }

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "private" {
  provider = "aws.vpc"
  count = "${length(compact(split(",", var.private_subnets)))}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "public" {
  provider = "aws.vpc"
  count = "${length(compact(split(",", var.public_subnets)))}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
