# all the network infrastructure for EKS

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                           = "${local.prefix}-vpc"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
  }
}

# internet gateway for the application load balancer

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-main"
  }
}

# public subnets for igw access

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                           = "${local.prefix}-public-a"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public_a"
  }

}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}
resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                           = "${local.prefix}-public-b"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-public_b"
  }

}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}
resource "aws_route" "public_internet_access_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# private subnets for EKS worker nodes

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                                           = "${local.prefix}-private-a"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                                           = "${local.prefix}-private-b"
    "kubernetes.io/cluster/${local.prefix}-eks" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Security group for EKS control plane

resource "aws_security_group" "eks_control_plane" {
  description = "Security group for EKS control plane"
  name        = "${local.prefix}-eks-control-plane"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow worker nodes to communicate with control plane"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_worker_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-eks-control-plane-sg"
  }
}

# Security group for EKS worker nodes

resource "aws_security_group" "eks_worker_nodes" {
  description = "Security group for EKS worker nodes"
  name        = "${local.prefix}-eks-worker-nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow worker to worker communication"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_worker_nodes.id]
  }

  ingress {
    description = "Allow control plane to worker communication"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Allow pod communication"
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

  tags = {
    Name = "${local.prefix}-eks-worker-nodes-sg"
  }
}

# endpoints to allow EKS accessing ECR, CloudWatch and Systems Manager

resource "aws_security_group" "endpoint_access" {
  description = "endpoint access for VPC endpoints"
  name        = "${local.prefix}-endpoint-access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-endpoint-access-sg"
  }
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-ecr-endpoint"
  }
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  security_group_ids = [
    aws_security_group.endpoint_access.id
  ]

  tags = {
    Name = "${local.prefix}-cloudwatch-endpoint"
  }
}

