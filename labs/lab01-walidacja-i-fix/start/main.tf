# Moduł logów aplikacji quotes-api.
# Napisany przez asystenta AI, przeszedł `terraform validate` i trafił do PR.
# Twoje zadanie: znaleźć, co jest z nim nie tak.

locals {
  prefix = "szkolenie-lab01-${var.uczestnik}"
}

resource "aws_s3_bucket" "logi" {
  bucket = "${local.prefix}-logs"

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_s3_bucket_versioning" "logi" {
  bucket = aws_s3_bucket.logi.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logi" {
  bucket = aws_s3_bucket.logi.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logi" {
  bucket = aws_s3_bucket.logi.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "kolektor" {
  name = "${local.prefix}-collector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}

resource "aws_iam_role_policy" "kolektor" {
  name = "${local.prefix}-write-logs"
  role = aws_iam_role.kolektor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = "${aws_s3_bucket.logi.arn}/*"
    }]
  })
}

resource "aws_security_group" "kolektor" {
  name        = "${local.prefix}-collector"
  description = "Kolektor logow"
  vpc_id      = var.vpc_id

  ingress {
    description = "Syslog z sieci wewnetrznej"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [var.cidr_vpc]
  }

  egress {
    description = "HTTPS do S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Projekt   = "ai-devops-cicd"
    Uczestnik = var.uczestnik
    Blok      = "lab01"
    Usuwac    = "tak"
  }
}
