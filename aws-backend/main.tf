terraform {
    # BOOTSTRAPING OF THE BACKEND #
    # 1. Run terrafrom apply with a local backend to create the needed backend resources
    # 2. Uncomment the backend config below to switch to the created remote backend

    backend "s3" {
        bucket         = "d0ej0hn-terraform-state" # REPLACE WITH YOUR BUCKET NAME
        key            = "states/import-bootstrap/terraform.tfstate"
        region         = "eu-central-1"
        dynamodb_table = "terraform-state-locking"
        encrypt        = true
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "d0ej0hn-terraform-state"
    force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket_public_access" {
    bucket = aws_s3_bucket.terraform_state.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_bucket_encryption" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_dynamodb_table" "terrafrom_locks" {
    name = "terraform-state-locking"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
}