provider "aws" {}

locals {
  naming_suffix = "apps-${var.naming_suffix}"
}

resource "aws_vpc" "appsvpc" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags {
    Name = "vpc-${local.naming_suffix}"
  }
}

resource "aws_route_table" "apps_route_table" {
  vpc_id = "${aws_vpc.appsvpc.id}"

  tags {
    Name = "route-table-${local.naming_suffix}"
  }
}

resource "aws_route" "ops" {
  route_table_id            = "${aws_route_table.apps_route_table.id}"
  destination_cidr_block    = "${var.route_table_cidr_blocks["ops_cidr"]}"
  vpc_peering_connection_id = "${var.vpc_peering_connection_ids["peering_to_ops"]}"
}

resource "aws_route" "peering" {
  route_table_id            = "${aws_route_table.apps_route_table.id}"
  destination_cidr_block    = "${var.route_table_cidr_blocks["peering_cidr"]}"
  vpc_peering_connection_id = "${var.vpc_peering_connection_ids["peering_to_peering"]}"
}

resource "aws_route" "nat" {
  route_table_id         = "${aws_route_table.apps_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.appsnatgw.id}"
}

resource "aws_route_table" "apps_public_route_table" {
  vpc_id = "${aws_vpc.appsvpc.id}"

  tags {
    Name = "public-route-table-${local.naming_suffix}"
  }
}

resource "aws_route" "igw" {
  route_table_id         = "${aws_route_table.apps_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.AppsRouteToInternet.id}"
}

resource "aws_eip" "appseip" {
  vpc = true
}

resource "aws_nat_gateway" "appsnatgw" {
  allocation_id = "${aws_eip.appseip.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"

  tags {
    Name = "natgw-${local.naming_suffix}"
  }
}

resource "aws_internet_gateway" "AppsRouteToInternet" {
  vpc_id = "${aws_vpc.appsvpc.id}"

  tags {
    Name = "igw-${local.naming_suffix}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.appsvpc.id}"
  cidr_block              = "${var.public_subnet_cidr_block}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.az}"

  tags {
    Name = "public-subnet-${local.naming_suffix}"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.apps_public_route_table.id}"
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.appsvpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
