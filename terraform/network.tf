resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC for ECS"
  }
}

resource "aws_subnet" "subnet_a" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "Subnet for ECS"
  }
}

resource "aws_security_group" "internal_traffic" {
  name        = "vpce"
  description = "Allow traffic within the VPC"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  # https://github.com/hashicorp/terraform-provider-aws/issues/265#issuecomment-471490744
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_task_access" {
  name        = "ecs_task_access"
  description = "Allow traffic within the VPC for ECS usage"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  # https://github.com/hashicorp/terraform-provider-aws/issues/265#issuecomment-471490744
  lifecycle {
    create_before_destroy = true
  }
}

# Need these endpoints for ECS to talk to other AWS services
# https://aws.amazon.com/blogs/security/how-to-connect-to-aws-secrets-manager-service-within-a-virtual-private-cloud/
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
# https://dev.to/danquack/private-fargate-deployment-with-vpc-endpoints-1h0p
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.subnet_a.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.internal_traffic.id]

  tags = {
    Name = "secrets-manager-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.subnet_a.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.internal_traffic.id]

  tags = {
    Name = "ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.subnet_a.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.internal_traffic.id]

  tags = {
    Name = "ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.internal_traffic.id]

  tags = {
    Name = "logs-endpoint"
  }
}

resource "aws_vpc_endpoint" "firehose" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.kinesis-firehose"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.internal_traffic.id]

  tags = {
    Name = "firehose-endpoint"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table-for-s3"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "s3-endpoint"
  }
}
