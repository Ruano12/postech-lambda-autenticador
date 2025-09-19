terraform {
  backend "s3" {
    bucket         = "my-terraform-state-turma-81"    # seu bucket
    key            = "infra-lambda.tfstate"     # caminho do state no S3
    region         = "us-east-1"             # região do bucket
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "postech_vpc" {
  filter {
    name   = "tag:Name"
    values = ["postech-vpc"]
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "tag:Name"
    values = ["postech-vpc-public-us-east-1a"]
  }
}

data "aws_subnet" "public_b" {
  filter {
    name   = "tag:Name"
    values = ["postech-vpc-public-us-east-1b"]
  }
}

resource "aws_security_group" "lambda_autenticador" {
  name        = "rds-postgres-sg"
  description = "Permitir acesso Postgres apenas do ECS"
  vpc_id      =  data.aws_vpc.postech_vpc.id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks =   ["0.0.0.0/0"]  # qualquer IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Empacota o código da lambda em zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda.zip"
}

# Lambda
resource "aws_lambda_function" "lambda_autenticador" {
    function_name = "lambda-lambda_autenticador"
    role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
    handler       = "index.handler"
    runtime       = "nodejs18.x"

    filename         = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256

    vpc_config {
        subnet_ids         = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]
        security_group_ids = [aws_security_group.lambda_autenticador.id]
    }

    environment {
        variables = {
        ENV = "dev"
        }
    }
}