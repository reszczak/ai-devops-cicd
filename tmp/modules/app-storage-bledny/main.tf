locals {
  prefix = "szkolenie-${var.blok}-${var.uczestnik}"
}

data "aws_availability_zones" "dostepne" {
  state = "available"
}

resource "aws_s3_bucket" "artefakty" {
  bucket = "${local.prefix}-artifacts"
}

resource "aws_s3_bucket_policy" "artefakty" {
  bucket = aws_s3_bucket.artefakty.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PipelineReadWrite"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123456789012:role/github-actions-deploy" }
        Action    = "s3:*"
        Resource  = "arn:aws:s3:::szkolenie-b1-artifacts/*"
      }
    ]
  })
}

resource "aws_vpc" "glowna" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.prefix}-vpc" }
}

resource "aws_subnet" "publiczna" {
  vpc_id                  = aws_vpc.glowna.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 8, 1)
  availability_zone       = data.aws_availability_zones.dostepne.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "${local.prefix}-public" }
}

resource "aws_internet_gateway" "glowna" {
  vpc_id = aws_vpc.glowna.id
  tags   = { Name = "${local.prefix}-igw" }
}

resource "aws_security_group" "aplikacja" {
  name        = "${local.prefix}-app"
  description = "Security group aplikacji"
  vpc_id      = aws_vpc.glowna.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH dla administratora"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefix}-app" }
}
