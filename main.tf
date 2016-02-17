resource "aws_vpc" "mod" {
  provider = "aws.${var.provider_alias}"
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support = "${var.enable_dns_support}"
  tags { Name = "${var.name}" }
}

resource "aws_internet_gateway" "mod" {
  provider = "aws.${var.provider_alias}"
  vpc_id = "${aws_vpc.mod.id}"
}

resource "aws_route_table" "public" {
  provider = "aws.${var.provider_alias}"
  vpc_id = "${aws_vpc.mod.id}"
  tags { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet_gateway" {
  provider = "aws.${var.provider_alias}"
    route_table_id = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mod.id}"
}

resource "aws_route_table" "private" {
  provider = "aws.${var.provider_alias}"
  vpc_id = "${aws_vpc.mod.id}"
  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "private" {
  provider = "aws.${var.provider_alias}"
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.private_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "public" {
  provider = "aws.${var.provider_alias}"
  vpc_id = "${aws_vpc.mod.id}"
  cidr_block = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count = "${length(compact(split(",", var.public_subnets)))}"
  tags { Name = "${var.name}-public" }

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "private" {
  provider = "aws.${var.provider_alias}"
  count = "${length(compact(split(",", var.private_subnets)))}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "public" {
  provider = "aws.${var.provider_alias}"
  count = "${length(compact(split(",", var.public_subnets)))}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
