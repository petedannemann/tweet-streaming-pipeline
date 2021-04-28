resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC for ECS"
  }
}

resource "aws_subnet" "private_subnet" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private subnet for ECS"
  }
}

resource "aws_subnet" "public_subnet" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "Public subnet for ECS"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecs-gateway"
  }
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "ecs-igw-routing-table"
  }
}

resource "aws_route_table_association" "igw_routing_table_association" {
  count          = 1
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.igw.id
}

resource "aws_eip" "this" {
  vpc = true

  tags = {
    Name = "ecs-elastic-ip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    "Name" = "ecs-NATGateway"
  }
}

resource "aws_route_table" "ngw" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "ecs-routing-table"
  }
}

resource "aws_route_table_association" "ngw_routing_table_association" {
  count          = 1
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.ngw.id
}

resource "aws_route_table" "vpce" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "ecs-routing-table"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint" {
  route_table_id  = "${aws_route_table.vpce.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "s3-vpc-endpoint"
  }
}

resource "aws_security_group" "vpce" {
  name   = "ecs-vpce"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # https://github.com/hashicorp/terraform-provider-aws/issues/265#issuecomment-471490744
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_task" {
  name   = "ecs"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Name = "dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.private_subnet.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpce.id]

  tags = {
    Name = "ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Name = "logs-endpoint"
  }
}

resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.private_subnet.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpce.id]

  tags = {
    Name = "secrets-manager-endpoint"
  }
}

resource "aws_vpc_endpoint" "firehose" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.kinesis-firehose"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]

  tags = {
    Name = "firehose-endpoint"
  }
}
