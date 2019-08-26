data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
  # no arguments
}

resource "aws_vpc" "base" {
  cidr_block           = var.vpc_cidr_address
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "${var.name}-vpc"
    Workspace = terraform.workspace
  }
}

resource "aws_internet_gateway" "base" {
  vpc_id = aws_vpc.base.id

  tags = {
    Name = "${var.name}-igw"
  }
}

// Public NAT Route table
resource "aws_route_table" "public_nat" {
  vpc_id = aws_vpc.base.id

  tags = {
    Name = "${var.name}-public-nat-rt"
  }
}

resource "aws_route" "public_nat" {
  route_table_id         = aws_route_table.public_nat.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.base.id
}

// Public routes A
resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.base.id

  tags = {
    Name = "${var.name}-public-a-rt"
  }
}

resource "aws_route" "public_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.base.id
}

resource "aws_route" "public_a_routed_via_nat" {
  count                  = length(var.ips_to_route_via_nat)
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = var.ips_to_route_via_nat[count.index]
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
}

// Public routes B
resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.base.id

  tags = {
    Name = "${var.name}-public-b-rt"
  }
}

resource "aws_route" "public_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.base.id
}

resource "aws_route" "public_b_routed_via_nat" {
  count                  = length(var.ips_to_route_via_nat)
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = var.ips_to_route_via_nat[count.index]
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b.id
}

// Public subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 2, 0)
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    Name = "${var.name}-PublicSubnetA"
    Tier = "public"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 2, 1)
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_region.current.name}b"

  tags = {
    Name = "${var.name}-PublicSubnetB"
    Tier = "public"
  }
}

// Public subnets
resource "aws_subnet" "public_nat_subnet_a" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 12)
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_region.current.name}a"

  tags = {
    Name = "${var.name}-PublicNATSubnetA"
    Tier = "public-nat"
  }
}

resource "aws_subnet" "public_nat_subnet_b" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 13)
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_region.current.name}b"

  tags = {
    Name = "${var.name}-PublicNATSubnetB"
    Tier = "public-nat"
  }
}

// Private subnet
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 8)
  map_public_ip_on_launch = "false"
  availability_zone       = "${data.aws_region.current.name}a" // a or b

  tags = {
    Name = "${var.name}-PrivateSubnetA"
    Tier = "private"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 9)
  map_public_ip_on_launch = "false"
  availability_zone       = "${data.aws_region.current.name}b" // a or b

  tags = {
    Name = "${var.name}-PrivateSubnetB"
    Tier = "private"
  }
}

// AWS Route table - public + private subnets
resource "aws_route_table_association" "public_pubsub_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route_table_association" "public_pubsub_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route_table_association" "public_privsub_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route_table_association" "public_privsub_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route_table_association" "public_pubnatsub_a" {
  subnet_id      = aws_subnet.public_nat_subnet_a.id
  route_table_id = aws_route_table.public_nat.id
}

resource "aws_route_table_association" "public_pubnatsub_b" {
  subnet_id      = aws_subnet.public_nat_subnet_b.id
  route_table_id = aws_route_table.public_nat.id
}

// Elastic IPs
resource "aws_eip" "elastic_ip_a" {
  vpc = true
}

resource "aws_eip" "elastic_ip_b" {
  vpc = true
}

// AWS NAT Gateways
resource "aws_nat_gateway" "nat_gateway_a" {
  depends_on    = [aws_internet_gateway.base]
  allocation_id = aws_eip.elastic_ip_a.id
  subnet_id     = aws_subnet.public_nat_subnet_a.id
}

resource "aws_nat_gateway" "nat_gateway_b" {
  depends_on    = [aws_internet_gateway.base]
  allocation_id = aws_eip.elastic_ip_b.id
  subnet_id     = aws_subnet.public_nat_subnet_b.id
}

// AWS Route tables
resource "aws_route_table" "nat_a" {
  vpc_id = aws_vpc.base.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_a.id
  }

  tags = {
    Name = "${var.name}-nat-a-rt" // a or b
  }
}

resource "aws_route_table" "nat_b" {
  vpc_id = aws_vpc.base.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_b.id
  }

  tags = {
    Name = "${var.name}-nat-b-rt" // a or b
  }
}

// Nated subnets
resource "aws_subnet" "nated_subnet_a" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 10)
  map_public_ip_on_launch = "false"
  availability_zone       = "${data.aws_region.current.name}a" // a or b

  tags = {
    Name = "${var.name}-NatedSubnetA"
    Tier = "nated"
  }
}

resource "aws_subnet" "nated_subnet_b" {
  vpc_id                  = aws_vpc.base.id
  cidr_block              = cidrsubnet(aws_vpc.base.cidr_block, 4, 11)
  map_public_ip_on_launch = "false"
  availability_zone       = "${data.aws_region.current.name}b" // a or b

  tags = {
    Name = "${var.name}-NatedSubnetB"
    Tier = "nated"
  }
}

// NAT Route table associaton
resource "aws_route_table_association" "nat_a" {
  subnet_id      = aws_subnet.nated_subnet_a.id
  route_table_id = aws_route_table.nat_a.id
}

resource "aws_route_table_association" "nat_b" {
  subnet_id      = aws_subnet.nated_subnet_b.id
  route_table_id = aws_route_table.nat_b.id
}

// DB Subnet group
resource "aws_db_subnet_group" "kiwi" {
  name       = "${var.name}-db_subnetgroup"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "${var.name}-default"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db_SecurityGroup"
  description = "Allow DBPort from AppSubnet."
  vpc_id      = aws_vpc.base.id

  tags = {
    Name = "${var.name}-default-db-sg"
    Tier = "database"
  }
}

// PostgreSQL
resource "aws_security_group_rule" "db-postgresql-ingress" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"
  cidr_blocks = compact(
    concat(
      [aws_vpc.base.cidr_block],
      concat(
        split(
          ",",
          var.use_default_db_ingress_cidr_blocks == true ? join(",", var.default_db_ingress_cidr_blocks) : join(",", [""]),
        ),
      ),
      var.custom_db_ingress_cidr_blocks,
    ),
  )
  security_group_id = aws_security_group.db.id
}

// MySQL
resource "aws_security_group_rule" "db-mysql-ingress" {
  type      = "ingress"
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"
  cidr_blocks = compact(
    concat(
      [aws_vpc.base.cidr_block],
      concat(
        split(
          ",",
          var.use_default_db_ingress_cidr_blocks == true ? join(",", var.default_db_ingress_cidr_blocks) : join(",", [""]),
        ),
      ),
      var.custom_db_ingress_cidr_blocks,
    ),
  )
  security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "db-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
}

// Redis/memcache subnet group
resource "aws_elasticache_subnet_group" "kiwi" {
  name        = "${var.name}-elasticache" // TODO why kiwi?
  description = "Kiwi default redis and memcache subnet group"
  subnet_ids  = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

resource "aws_security_group" "elasti_cache" {
  name        = "${var.name}-ElastiCacheSecurityGroup"
  description = "Allow ElastiCache ports from internal network."
  vpc_id      = aws_vpc.base.id

  tags = {
    Name = "${var.name}-default-elasti_cache-sg"
    Tier = "elasticache"
  }
}

resource "aws_security_group_rule" "elasti_cache-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elasti_cache.id
}

// Redis
resource "aws_security_group_rule" "elasti_cache-redis-ingress" {
  type      = "ingress"
  from_port = 6379
  to_port   = 6379
  protocol  = "tcp"

  cidr_blocks = [
    aws_vpc.base.cidr_block,
  ]

  security_group_id = aws_security_group.elasti_cache.id
}

// Memcache
resource "aws_security_group_rule" "elasti_cache-memcache-ingress" {
  type      = "ingress"
  from_port = 11211
  to_port   = 11211
  protocol  = "tcp"

  cidr_blocks = [
    aws_vpc.base.cidr_block,
  ]

  security_group_id = aws_security_group.elasti_cache.id
}

// Private security group
resource "aws_security_group" "private" {
  name        = "${var.name}-PrivateSecurityGroup"
  description = "Allow all traffic within VPC."
  vpc_id      = aws_vpc.base.id

  tags = {
    Name = "${var.name}-default-private-sg"
    Tier = "private"
  }
}

resource "aws_security_group_rule" "private-ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "private-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private.id
}

// Outputs
output "vpc_id" {
  value = aws_vpc.base.id
}

output "vpc_cidr" {
  value = aws_vpc.base.cidr_block
}

output "public_subnet_a" {
  value = aws_subnet.public_subnet_a.id
}

output "public_subnet_b" {
  value = aws_subnet.public_subnet_b.id
}

output "private_subnet_a" {
  value = aws_subnet.private_subnet_a.id
}

output "private_subnet_b" {
  value = aws_subnet.private_subnet_b.id
}

output "nated_subnet_a" {
  value = aws_subnet.nated_subnet_a.id
}

output "nated_subnet_b" {
  value = aws_subnet.nated_subnet_b.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.kiwi.id
}

output "elasticache_subnet_group" {
  value = aws_elasticache_subnet_group.kiwi.id
}

output "elasticache_security_group" {
  value = aws_security_group.elasti_cache.id
}

output "db_security_group" {
  value = aws_security_group.db.id
}

output "private_security_group" {
  value = aws_security_group.private.id
}

output "nat_eip_a" {
  value = aws_nat_gateway.nat_gateway_a.public_ip
}

output "nat_eip_b" {
  value = aws_nat_gateway.nat_gateway_b.public_ip
}

output "output_map" {
  value = {
    "vpc_id"                     = aws_vpc.base.id
    "vpc_cidr"                   = aws_vpc.base.cidr_block
    "public_subnet_a"            = aws_subnet.public_subnet_a.id
    "public_subnet_b"            = aws_subnet.public_subnet_b.id
    "private_subnet_a"           = aws_subnet.private_subnet_a.id
    "private_subnet_b"           = aws_subnet.private_subnet_b.id
    "nated_subnet_a"             = aws_subnet.nated_subnet_a.id
    "nated_subnet_b"             = aws_subnet.nated_subnet_b.id
    "db_subnet_group"            = aws_db_subnet_group.kiwi.id
    "db_security_group"          = aws_security_group.db.id
    "elasticache_subnet_group"   = aws_elasticache_subnet_group.kiwi.id
    "elasticache_security_group" = aws_security_group.elasti_cache.id
    "private_security_group"     = aws_security_group.private.id
    "nat_ip_a"                   = aws_nat_gateway.nat_gateway_a.public_ip
    "nat_ip_b"                   = aws_nat_gateway.nat_gateway_b.public_ip
  }
}
