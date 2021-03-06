terraform {
  required_version = ">= 0.11.3"
}

provider "random" {
  version = "~> 1.2.0"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "private_artifacts" {
  bucket = "${var.bucket_prefix}-private-artifacts"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD", "POST", "DELETE"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket" "public_artifacts" {
  bucket = "${var.bucket_prefix}-public-artifacts"
  acl    = "public-read"

  versioning = {
    enabled = true
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD", "POST", "DELETE"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    id                                     = "cleanup-cruft"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = 3
    }
  }
}

resource "aws_s3_bucket_policy" "public_artifacts" {
  bucket = "${aws_s3_bucket.public_artifacts.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "${aws_s3_bucket.public_artifacts.arn}/*"
        }
    ]
}
POLICY
}

resource "aws_s3_bucket" "public_blobs" {
  bucket = "${var.bucket_prefix}-public-blobs"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "private_blobs" {
  bucket = "${var.bucket_prefix}-private-blobs"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_origins = ["*"]
    allowed_methods = ["GET", "PUT", "HEAD", "POST", "DELETE"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.bucket_prefix}-backups"
  acl    = "private"

  versioning = {
    enabled = true
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
  }

  lifecycle_rule {
    id                                     = "cleanup-old-backups"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 14

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = 14
    }
  }
}

resource "azurerm_resource_group" "base" {
  name     = "${var.azure_resource_group_name}"
  location = "${var.azure_region}"
}

resource "azurerm_storage_account" "base" {
  name                     = "${azurerm_resource_group.base.name}"
  resource_group_name      = "${azurerm_resource_group.base.name}"
  location                 = "${var.azure_region}"
  account_tier             = "Standard"
  account_replication_type = "RAGRS"

  tags {
    environment = "staging"
    managed_by  = "terraform"
  }
}
