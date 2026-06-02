data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
      Name = "${var.vpc_name}"
    }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.title}-public-subnet-1"
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.title}-public-subnet-2"
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                            = "${var.title}-private-subnet-1"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                            = "${var.title}-private-subnet-2"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.title}-igw"
  }
}

resource "aws_eip" "nat_eips" {
  for_each = toset(["subnet_1", "subnet_2"])
  domain   = "vpc"

  tags = {
    Name = "${var.title}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "mains" {
  for_each = {
    subnet_1 = aws_subnet.public_subnet_1.id
    subnet_2 = aws_subnet.public_subnet_2.id
  }
  subnet_id         = each.value
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eips[each.key].id

  tags = {
    Name = "${var.title}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.title}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_associations" {
  for_each = {
    subnet_1 = aws_subnet.public_subnet_1.id
    subnet_2 = aws_subnet.public_subnet_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  for_each = toset(["subnet_1", "subnet_2"])
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mains[each.key].id
  }

  tags = {
    Name = "${var.title}-private-rt-${each.key}"
  }
}

resource "aws_route_table_association" "private_rt_associations" {
  for_each = {
    subnet_1 = aws_subnet.private_subnet_1.id
    subnet_2 = aws_subnet.private_subnet_2.id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt[each.key].id
}