resource "aws_kms_key" "bucket_key" {
  description             = "This key is used to encrypt APPS buckets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "${data.aws_caller_identity.current.arn}",
                  "${data.aws_caller_identity.current.account_id}"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow services use of the key",
            "Effect": "Allow",
            "Principal": {
                "Service": "s3.amazonaws.com"
            },
            "Action": [
                "kms:Encrypt",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_s3_bucket" "log_archive_bucket" {
  bucket = var.s3_bucket_name["archive_log"]
  # acl    = var.s3_bucket_acl["archive_log"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  tags = {
    Name = "s3-log-archive-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_archive_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  rule {
    id = "log_archive_bucket_rule_1"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "log_archive_bucket_versioning" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "log_archive_bucket_acl" {
  bucket = aws_s3_bucket.log_archive_bucket.id
  acl    = var.s3_bucket_acl["archive_log"]
}

resource "aws_s3_bucket_metric" "log_archive_bucket_logging" {
  bucket = var.s3_bucket_name["archive_log"]
  name   = "log_archive_bucket_metric"
}

resource "aws_s3_bucket_public_access_block" "log_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.log_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "archive_log_policy" {
  bucket = var.s3_bucket_name["archive_log"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["archive_log"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "data_archive_bucket" {
  bucket = var.s3_bucket_name["archive_data"]
  # acl    = var.s3_bucket_acl["archive_data"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  # logging {
  #   target_bucket = aws_s3_bucket.log_archive_bucket.id
  #   target_prefix = "data_archive_bucket/"
  # }

  tags = {
    Name = "s3-data-archive-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "data_archive_bucket_versioning" {
  bucket = var.s3_bucket_name["archive_data"]
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.data_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "data_archive_bucket_acl" {
  bucket = var.s3_bucket_name["archive_data"]
  acl    = var.s3_bucket_acl["archive_data"]
}

resource "aws_s3_bucket_logging" "data_archive_bucket_logging" {
  bucket = var.s3_bucket_name["archive_data"]

  target_bucket = aws_s3_bucket.log_archive_bucket.id
  target_prefix = "data_archive_bucket/"
}

resource "aws_s3_bucket_lifecycle_configuration" "data_archive_bucket_lifecycle" {
  bucket = var.s3_bucket_name["archive_data"]

  rule {
    id = "standard_ia_transition"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    status = "Enabled"
  }

  rule {
    id = "internal_tableau_green"


    filter {
      prefix = "tableau-int/green/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }

  rule {
    id = "internal_tableau_blue"


    filter {
      prefix = "tableau-int/blue/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }

  rule {
    id = "internal_tableau_staging"


    filter {
      prefix = "tableau-int/staging/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }

  rule {
    id = "external_tableau_green"


    filter {
      prefix = "tableau-ext/green/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }

  rule {
    id = "external_tableau_blue"


    filter {
      prefix = "tableau-ext/blue/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }

  rule {
    id = "external_tableau_staging"


    filter {
      prefix = "tableau-ext/staging/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    status = "Enabled"
  }
}


resource "aws_s3_bucket_metric" "data_archive_bucket_logging" {
  bucket = var.s3_bucket_name["archive_data"]
  name   = "data_archive_bucket_metric"
}

resource "aws_s3_bucket_policy" "data_archive_bucket" {
  bucket = var.s3_bucket_name["archive_data"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["archive_data"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "data_working_bucket" {
  bucket = var.s3_bucket_name["working_data"]
  acl    = var.s3_bucket_acl["working_data"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "data_working_bucket/"
  }

  tags = {
    Name = "s3-data-working-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "data_working_bucket_versioning" {
  bucket = aws_s3_bucket.data_working_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_working_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.data_working_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_metric" "data_working_bucket_logging" {
  bucket = var.s3_bucket_name["working_data"]
  name   = "data_working_bucket_metric"
}

resource "aws_s3_bucket_public_access_block" "data_working_bucket_pub_block" {
  bucket = aws_s3_bucket.data_working_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "data_working_bucket" {
  bucket = var.s3_bucket_name["working_data"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["working_data"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "airports_archive_bucket" {
  bucket = var.s3_bucket_name["airports_archive"]
  acl    = var.s3_bucket_acl["airports_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "airports_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-airports-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "airports_archive_bucket_versioning" {
  bucket = aws_s3_bucket.airports_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "airports_archive_bucket-config" {
  bucket = aws_s3_bucket.airports_archive_bucket.id

  rule {
    id = "airports_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airports_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.airports_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "airports_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.airports_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "airports_archive_policy" {
  bucket = var.s3_bucket_name["airports_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["airports_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "airports_internal_bucket" {
  bucket = var.s3_bucket_name["airports_internal"]
  acl    = var.s3_bucket_acl["airports_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "airports_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-airports-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "airports_internal_bucket_versioning" {
  bucket = aws_s3_bucket.airports_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airports_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.airports_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "airports_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.airports_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "airports_internal_policy" {
  bucket = var.s3_bucket_name["airports_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["airports_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "airports_working_bucket" {
  bucket = var.s3_bucket_name["airports_working"]
  acl    = var.s3_bucket_acl["airports_working"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "airports_working_bucket/"
  }

  tags = {
    Name = "s3-dq-airports-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "airports_working_bucket_versioning" {
  bucket = aws_s3_bucket.airports_working_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airports_working_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.airports_working_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "airports_working_bucket_pub_block" {
  bucket = aws_s3_bucket.airports_working_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "airports_working_policy" {
  bucket = var.s3_bucket_name["airports_working"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["airports_working"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "oag_archive_bucket" {
  bucket = var.s3_bucket_name["oag_archive"]
  acl    = var.s3_bucket_acl["oag_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  # rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "oag_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-oag-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "oag_archive_bucket-config" {
  bucket = aws_s3_bucket.oag_archive_bucket.id

  rule {
    id = "oag_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}



resource "aws_s3_bucket_versioning" "oag_archive_bucket_versioning" {
  bucket = aws_s3_bucket.oag_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "oag_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.oag_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "oag_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.oag_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "oag_archive_policy" {
  bucket = var.s3_bucket_name["oag_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["oag_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "oag_internal_bucket" {
  bucket = var.s3_bucket_name["oag_internal"]
  acl    = var.s3_bucket_acl["oag_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "oag_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-oag-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "oag_internal_bucket_versioning" {
  bucket = aws_s3_bucket.oag_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "oag_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.oag_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "oag_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.oag_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "oag_internal_policy" {
  bucket = var.s3_bucket_name["oag_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["oag_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "oag_transform_bucket" {
  bucket = var.s3_bucket_name["oag_transform"]
  acl    = var.s3_bucket_acl["oag_transform"]
  # region = var.region

  # server_side_encryption_configuration {
  # rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "oag_transform_bucket/"
  }

  tags = {
    Name = "s3-dq-oag-transform-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "oag_transform_bucket_versioning" {
  bucket = aws_s3_bucket.oag_transform_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "oag_transform_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.oag_transform_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "oag_transform_bucket_pub_block" {
  bucket = aws_s3_bucket.oag_transform_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "oag_transform_policy" {
  bucket = var.s3_bucket_name["oag_transform"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["oag_transform"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "oag_transform_bucket_logging" {
  bucket = var.s3_bucket_name["oag_transform"]
  name   = "oag_transform_bucket_metric"
}

resource "aws_s3_bucket" "acl_archive_bucket" {
  bucket = var.s3_bucket_name["acl_archive"]
  acl    = var.s3_bucket_acl["acl_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "acl_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-acl-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "acl_archive_bucket_versioning" {
  bucket = aws_s3_bucket.acl_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "acl_archive_bucket-config" {
  bucket = aws_s3_bucket.acl_archive_bucket.id

  rule {
    id = "acl_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "acl_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.acl_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "acl_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.acl_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "acl_archive_policy" {
  bucket = var.s3_bucket_name["acl_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["acl_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "acl_internal_bucket" {
  bucket = var.s3_bucket_name["acl_internal"]
  acl    = var.s3_bucket_acl["acl_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "acl_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-acl-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "acl_internal_bucket_versioning" {
  bucket = aws_s3_bucket.acl_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "acl_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.acl_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "acl_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.acl_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "acl_internal_policy" {
  bucket = var.s3_bucket_name["acl_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["acl_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "reference_data_archive_bucket" {
  bucket = var.s3_bucket_name["reference_data_archive"]
  acl    = var.s3_bucket_acl["reference_data_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "reference_data_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-reference-data-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "reference_data_archive_bucket_versioning" {
  bucket = aws_s3_bucket.reference_data_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reference_data_archive_bucket-config" {
  bucket = aws_s3_bucket.reference_data_archive_bucket.id

  rule {
    id = "reference_data_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reference_data_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.reference_data_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reference_data_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.reference_data_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "reference_data_archive_policy" {
  bucket = var.s3_bucket_name["reference_data_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["reference_data_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "reference_data_internal_bucket" {
  bucket = var.s3_bucket_name["reference_data_internal"]
  acl    = var.s3_bucket_acl["reference_data_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "reference_data_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-reference-data-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "reference_data_internal_bucket_versioning" {
  bucket = aws_s3_bucket.reference_data_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reference_data_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.reference_data_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reference_data_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.reference_data_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "reference_data_internal_policy" {
  bucket = var.s3_bucket_name["reference_data_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["reference_data_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "consolidated_schedule_bucket" {
  bucket = var.s3_bucket_name["consolidated_schedule"]
  acl    = var.s3_bucket_acl["consolidated_schedule"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "consolidated_schedule_bucket/"
  }

  tags = {
    Name = "s3-dq-consolidated-schedule-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "consolidated_schedule_bucket_versioning" {
  bucket = aws_s3_bucket.consolidated_schedule_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "consolidated_schedule_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.consolidated_schedule_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "consolidated_schedule_bucket_pub_block" {
  bucket = aws_s3_bucket.consolidated_schedule_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "consolidated_schedule_policy" {
  bucket = var.s3_bucket_name["consolidated_schedule"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["consolidated_schedule"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "consolidated_schedule_bucket_logging" {
  bucket = var.s3_bucket_name["consolidated_schedule"]
  name   = "consolidated_schedule_bucket_metric"
}

resource "aws_s3_bucket" "api_archive_bucket" {
  bucket = var.s3_bucket_name["api_archive"]
  acl    = var.s3_bucket_acl["api_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-api-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "api_archive_bucket-config" {
  bucket = aws_s3_bucket.api_archive_bucket.id

  rule {
    id = "api_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "api_archive_bucket_versioning" {
  bucket = aws_s3_bucket.api_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "api_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.api_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_archive_policy" {
  bucket = var.s3_bucket_name["api_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_archive_bucket_logging" {
  bucket = var.s3_bucket_name["api_archive"]
  name   = "api_archive_bucket_metric"
}

resource "aws_s3_bucket" "api_internal_bucket" {
  bucket = var.s3_bucket_name["api_internal"]
  acl    = var.s3_bucket_acl["api_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-api-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "api_internal_bucket_versioning" {
  bucket = aws_s3_bucket.api_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "api_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.api_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_internal_policy" {
  bucket = var.s3_bucket_name["api_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_internal_bucket_logging" {
  bucket = var.s3_bucket_name["api_internal"]
  name   = "api_internal_bucket_metric"
}

resource "aws_s3_bucket" "api_record_level_scoring_bucket" {
  bucket = var.s3_bucket_name["api_record_level_scoring"]
  acl    = var.s3_bucket_acl["api_record_level_scoring"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_record_level_scoring_bucket/"
  }

  tags = {
    Name = "s3-dq-api-record-level-scoring-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "api_record_level_scoring_bucket_versioning" {
  bucket = aws_s3_bucket.api_record_level_scoring_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_record_level_scoring_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_record_level_scoring_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "api_record_level_scoring_bucket_pub_block" {
  bucket = aws_s3_bucket.api_record_level_scoring_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_record_level_scoring_policy" {
  bucket = var.s3_bucket_name["api_record_level_scoring"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_record_level_scoring"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_record_level_scoring_logging" {
  bucket = var.s3_bucket_name["api_record_level_scoring"]
  name   = "api_record_level_scoring_bucket_metric"
}

resource "aws_s3_bucket" "cross_record_scored_bucket" {
  bucket = var.s3_bucket_name["cross_record_scored"]
  acl    = var.s3_bucket_acl["cross_record_scored"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "cross_record_scored_bucket/"
  }

  tags = {
    Name = "s3-dq-cross-record-scored-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "cross_record_scored_bucket_versioning" {
  bucket = aws_s3_bucket.cross_record_scored_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cross_record_scored_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.cross_record_scored_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cross_record_scored_bucket_pub_block" {
  bucket = aws_s3_bucket.cross_record_scored_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cross_record_scored_policy" {
  bucket = var.s3_bucket_name["cross_record_scored"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["cross_record_scored"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "cross_record_scored_logging" {
  bucket = var.s3_bucket_name["cross_record_scored"]
  name   = "api_cross_record_scored_bucket_metric"
}

resource "aws_s3_bucket" "gait_internal_bucket" {
  bucket = var.s3_bucket_name["gait_internal"]
  acl    = var.s3_bucket_acl["gait_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "gait_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-gait-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "gait_internal_bucket_versioning" {
  bucket = aws_s3_bucket.gait_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gait_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.gait_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "gait_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.gait_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "gait_internal_policy" {
  bucket = var.s3_bucket_name["gait_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["gait_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "reporting_internal_working_bucket" {
  bucket = var.s3_bucket_name["reporting_internal_working"]
  acl    = var.s3_bucket_acl["reporting_internal_working"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "reporting_internal_working_bucket/"
  }

  tags = {
    Name = "s3-dq-reporting-internal-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "reporting_internal_working_bucket_versioning" {
  bucket = aws_s3_bucket.reporting_internal_working_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reporting_internal_working_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.reporting_internal_working_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reporting_internal_working_bucket_pub_block" {
  bucket = aws_s3_bucket.reporting_internal_working_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "reporting_internal_working_policy" {
  bucket = var.s3_bucket_name["reporting_internal_working"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["reporting_internal_working"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "reporting_internal_working_logging" {
  bucket = var.s3_bucket_name["reporting_internal_working"]
  name   = "reporting_internal_working_bucket_metric"
}

resource "aws_s3_bucket" "athena_log_bucket" {
  bucket = var.s3_bucket_name["athena_log"]
  acl    = var.s3_bucket_acl["athena_log"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "athena_log_bucket/"
  }

  tags = {
    Name = "s3-dq-athena-log-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "athena_log_bucket_versioning" {
  bucket = aws_s3_bucket.athena_log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_log_bucket_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.athena_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "athena_log_policy" {
  bucket = var.s3_bucket_name["athena_log"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["athena_log"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "mds_extract_bucket" {
  bucket = var.s3_bucket_name["mds_extract"]
  acl    = var.s3_bucket_acl["mds_extract"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "mds_extract_bucket/"
  }

  tags = {
    Name = "s3-dq-mds-extract-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "mds_extract_bucket_versioning" {
  bucket = aws_s3_bucket.mds_extract_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mds_extract_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.mds_extract_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "mds_extract_bucket_pub_block" {
  bucket = aws_s3_bucket.mds_extract_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "mds_extract_policy" {
  bucket = var.s3_bucket_name["mds_extract"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["mds_extract"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "raw_file_index_internal_bucket" {
  bucket = var.s3_bucket_name["raw_file_index_internal"]
  acl    = var.s3_bucket_acl["raw_file_index_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "raw_file_index_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-raw-file-retrieval-index-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "raw_file_index_internal_bucket_versioning" {
  bucket = aws_s3_bucket.raw_file_index_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_file_index_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.raw_file_index_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_file_index_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.raw_file_index_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "raw_file_index_internal_policy" {
  bucket = var.s3_bucket_name["raw_file_index_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["raw_file_index_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "fms_working_bucket" {
  bucket = var.s3_bucket_name["fms_working"]
  acl    = var.s3_bucket_acl["fms_working"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "fms_working_bucket/"
  }

  tags = {
    Name = "s3-dq-fms-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "fms_working_bucket_versioning" {
  bucket = aws_s3_bucket.fms_working_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fms_working_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.fms_working_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "fms_working_bucket_pub_block" {
  bucket = aws_s3_bucket.fms_working_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "fms_working_policy" {
  bucket = var.s3_bucket_name["fms_working"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["fms_working"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "drt_export" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["drt_export"]
  acl    = var.s3_bucket_acl["drt_export"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "drt_export_bucket/"
  }

  tags = {
    Name = "s3-dq-drt-extra-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "drt_export_versioning" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.drt_export[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "drt_export_server_side_encryption_configuration" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.drt_export[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "drt_export_bucket_pub_block" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.drt_export[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "drt_export_policy" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["drt_export"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["drt_export"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "drt_export_logging" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["drt_export"]
  name   = "drt_export_bucket_metric"
}

resource "aws_ssm_parameter" "drt_export_S3_kms" {
  count = var.namespace == "notprod" ? 1 : 0
  name  = "DRT_S3_KMS_KEY_ID"
  type  = "SecureString"
  value = aws_kms_key.bucket_key.key_id
}

resource "aws_s3_bucket" "drt_working_bucket" {
  bucket = var.s3_bucket_name["drt_working"]
  acl    = var.s3_bucket_acl["drt_working"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "drt_working_bucket/"
  }

  tags = {
    Name = "s3-dq-drt-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "drt_working_bucket_versioning" {
  bucket = aws_s3_bucket.drt_working_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "drt_working_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.drt_working_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "drt_working_bucket_pub_block" {
  bucket = aws_s3_bucket.drt_working_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "drt_working_policy" {
  bucket = var.s3_bucket_name["drt_working"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["drt_working"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "drt_working_logging" {
  bucket = var.s3_bucket_name["drt_working"]
  name   = "drt_working_bucket_metric"
}

resource "aws_s3_bucket" "nats_archive_bucket" {
  bucket = var.s3_bucket_name["nats_archive"]
  acl    = var.s3_bucket_acl["nats_archive"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "nats_archive_bucket/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-nats-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "nats_archive_bucket_versioning" {
  bucket = aws_s3_bucket.nats_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "nats_archive_bucket-config" {
  bucket = aws_s3_bucket.nats_archive_bucket.id

  rule {
    id = "nats_archive_bucket_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nats_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.nats_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nats_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.nats_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "nats_archive_policy" {
  bucket = var.s3_bucket_name["nats_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["nats_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "nats_internal_bucket" {
  bucket = var.s3_bucket_name["nats_internal"]
  acl    = var.s3_bucket_acl["nats_internal"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  # versioning {
  #  enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "nats_internal/"
  }

  tags = {
    Name = "nats-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "nats_internal_bucket_versioning" {
  bucket = aws_s3_bucket.nats_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nats_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.nats_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nats_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.nats_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "nats_internal_policy" {
  bucket = var.s3_bucket_name["nats_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["nats_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket" "cdlz_bitd_input" {
  bucket = var.s3_bucket_name["cdlz_bitd_input"]
  acl    = var.s3_bucket_acl["cdlz_bitd_input"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "cdlz_bitd_input/"
  }

  tags = {
    Name = "s3-dq-cdlz-bitd-input-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "cdlz_bitd_input_versioning" {
  bucket = aws_s3_bucket.cdlz_bitd_input.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdlz_bitd_input_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.cdlz_bitd_input.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cdlz_bitd_input_pub_block" {
  bucket = aws_s3_bucket.cdlz_bitd_input.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cdlz_bitd_input_policy" {
  bucket = var.s3_bucket_name["cdlz_bitd_input"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["cdlz_bitd_input"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "cdlz_bitd_input_logging" {
  bucket = var.s3_bucket_name["cdlz_bitd_input"]
  name   = "cdlz_bitd_input_bucket_metric"
}

resource "aws_s3_bucket" "api_arrivals_bucket" {
  bucket = var.s3_bucket_name["api_arrivals"]
  acl    = var.s3_bucket_acl["api_arrivals"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_arrivals/"
  }

  tags = {
    Name = "s3-dq-api-arrivals-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "api_arrivals_bucket_versioning" {
  bucket = aws_s3_bucket.api_arrivals_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_arrivals_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_arrivals_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "s3-dq-api-arrivals-test" {
  bucket = var.s3_bucket_name["api_arrivals"]
  key    = "reference/"
}

resource "aws_s3_bucket_public_access_block" "api_arrivals_bucket_pub_block" {
  bucket = aws_s3_bucket.api_arrivals_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_arrivals_policy" {
  bucket = var.s3_bucket_name["api_arrivals"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_arrivals"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_arrivals_logging" {
  bucket = var.s3_bucket_name["api_arrivals"]
  name   = "api_arrivals_bucket_metric"
}

resource "aws_s3_bucket" "accuracy_score_bucket" {
  bucket = var.s3_bucket_name["accuracy_score"]
  acl    = var.s3_bucket_acl["accuracy_score"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "accuracy_score/"
  }

  tags = {
    Name = "s3-dq-accuracy-score-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "accuracy_score_bucket_versioning" {
  bucket = aws_s3_bucket.accuracy_score_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "accuracy_score_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.accuracy_score_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "accuracy_score_bucket_pub_block" {
  bucket = aws_s3_bucket.accuracy_score_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "accuracy_score_policy" {
  bucket = var.s3_bucket_name["accuracy_score"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["accuracy_score"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "accuracy_score_logging" {
  bucket = var.s3_bucket_name["accuracy_score"]
  name   = "accuracy_score_bucket_metric"
}

resource "aws_s3_bucket" "api_cdlz_msk_bucket" {
  bucket = var.s3_bucket_name["api_cdlz_msk"]
  acl    = var.s3_bucket_acl["api_cdlz_msk"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_cdlz_msk/"
  }

  tags = {
    Name = "s3-dq-api-cdlz-msk-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "api_cdlz_msk_bucket_versioning" {
  bucket = aws_s3_bucket.api_cdlz_msk_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_cdlz_msk_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_cdlz_msk_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "api_cdlz_msk_bucket_pub_block" {
  bucket = aws_s3_bucket.api_cdlz_msk_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_cdlz_msk_bucket_policy" {
  bucket = var.s3_bucket_name["api_cdlz_msk"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_cdlz_msk"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_cdlz_msk_bucket_logging" {
  bucket = var.s3_bucket_name["api_cdlz_msk"]
  name   = "api_cdlz_msk_metric"
}

resource "aws_s3_bucket" "api_rls_xrs_reconciliation" {
  bucket = var.s3_bucket_name["api_rls_xrs_reconciliation"]
  acl    = var.s3_bucket_acl["api_rls_xrs_reconciliation"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "api_rls_xrs_reconciliation/"
  }

  tags = {
    Name = "s3-dq-rls-xrs-reconciliation-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "api_rls_xrs_reconciliation_versioning" {
  bucket = aws_s3_bucket.api_rls_xrs_reconciliation.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "api_rls_xrs_reconciliation_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.api_rls_xrs_reconciliation.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "api_rls_xrs_reconciliation_pub_block" {
  bucket = aws_s3_bucket.api_rls_xrs_reconciliation.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "api_rls_xrs_reconciliation_bucket_policy" {
  bucket = var.s3_bucket_name["api_rls_xrs_reconciliation"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["api_rls_xrs_reconciliation"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "api_rls_xrs_reconciliation_bucket_logging" {
  bucket = var.s3_bucket_name["api_rls_xrs_reconciliation"]
  name   = "api_rls_xrs_reconciliation_metric"
}

resource "aws_s3_bucket" "dq_fs_archive" {
  bucket = var.s3_bucket_name["dq_fs_archive"]
  acl    = var.s3_bucket_acl["dq_fs_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_fs_archive/"
  }

  tags = {
    Name = "s3-dq-fs-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_fs_archive_versioning" {
  bucket = aws_s3_bucket.dq_fs_archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_fs_archive_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_fs_archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_fs_archive_pub_block" {
  bucket = aws_s3_bucket.dq_fs_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_fs_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_fs_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_fs_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_fs_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_fs_archive"]
  name   = "dq_fs_archive_metric"
}

resource "aws_s3_bucket" "dq_fs_internal" {
  bucket = var.s3_bucket_name["dq_fs_internal"]
  acl    = var.s3_bucket_acl["dq_fs_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_fs_internal/"
  }

  tags = {
    Name = "s3-dq-fs-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_fs_internal_versioning" {
  bucket = aws_s3_bucket.dq_fs_internal.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_fs_internal_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_fs_internal.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_fs_internal_pub_block" {
  bucket = aws_s3_bucket.dq_fs_internal.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_fs_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_fs_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_fs_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_fs_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_fs_internal"]
  name   = "dq_fs_internal_metric"
}

resource "aws_s3_bucket" "dq_aws_config_bucket" {
  bucket = var.s3_bucket_name["dq_aws_config"]
  acl    = var.s3_bucket_acl["dq_aws_config"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_aws_config/"
  }

  tags = {
    Name = "s3-dq-aws-config-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_aws_config_bucket_versioning" {
  bucket = aws_s3_bucket.dq_aws_config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_aws_config_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_aws_config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_aws_config_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_aws_config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_aws_config_bucket_policy" {
  bucket = var.s3_bucket_name["dq_aws_config"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_aws_config"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_aws_config_bucket_logging" {
  bucket = var.s3_bucket_name["dq_aws_config"]
  name   = "dq_aws_config_metric"
}

resource "aws_s3_bucket" "dq_asn_archive_bucket" {
  bucket = var.s3_bucket_name["dq_asn_archive"]
  acl    = var.s3_bucket_acl["dq_asn_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_asn_archive/"
  }

  tags = {
    Name = "s3-dq-asn-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_asn_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_asn_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_asn_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_asn_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_asn_archive_pub_block" {
  bucket = aws_s3_bucket.dq_asn_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_asn_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_asn_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_asn_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_asn_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_asn_archive"]
  name   = "dq_asn_archive_metric"
}

resource "aws_s3_bucket" "dq_asn_internal_bucket" {
  bucket = var.s3_bucket_name["dq_asn_internal"]
  acl    = var.s3_bucket_acl["dq_asn_internal"]

  # versioning {
  # enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_asn_internal/"
  }

  tags = {
    Name = "s3-dq-asn-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_asn_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_asn_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_asn_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_asn_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_asn_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_asn_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_asn_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_asn_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_asn_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_asn_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_asn_internal"]
  name   = "dq_asn_internal_metric"
}

resource "aws_s3_bucket" "dq_snsgb_archive_bucket" {
  bucket = var.s3_bucket_name["dq_snsgb_archive"]
  acl    = var.s3_bucket_acl["dq_snsgb_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_snsgb_archive/"
  }

  tags = {
    Name = "s3-dq-snsgb-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_snsgb_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_snsgb_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_snsgb_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_snsgb_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_snsgb_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_snsgb_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_snsgb_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_snsgb_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_snsgb_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_snsgb_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_snsgb_archive"]
  name   = "dq_snsgb_archive_metric"
}

resource "aws_s3_bucket" "dq_snsgb_internal_bucket" {
  bucket = var.s3_bucket_name["dq_snsgb_internal"]
  acl    = var.s3_bucket_acl["dq_snsgb_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_snsgb_internal/"
  }

  tags = {
    Name = "s3-dq-snsgb-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_snsgb_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_snsgb_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_snsgb_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_snsgb_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_snsgb_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_snsgb_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_snsgb_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_snsgb_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_snsgb_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_snsgb_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_snsgb_internal"]
  name   = "dq_snsgb_internal_metric"
}

resource "aws_s3_bucket" "dq_asn_marine_archive_bucket" {
  bucket = var.s3_bucket_name["dq_asn_marine_archive"]
  acl    = var.s3_bucket_acl["dq_asn_marine_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_asn_marine_archive/"
  }

  tags = {
    Name = "s3-dq-asn-marine-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_asn_marine_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_asn_marine_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_asn_marine_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_asn_marine_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_asn_marine_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_asn_marine_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_asn_marine_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_asn_marine_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_asn_marine_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_asn_marine_archive_bucket]

}

resource "aws_s3_bucket_metric" "dq_asn_marine_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_asn_marine_archive"]
  name   = "dq_asn_marine_archive_metric"
}

resource "aws_s3_bucket" "dq_asn_marine_internal_bucket" {
  bucket = var.s3_bucket_name["dq_asn_marine_internal"]
  acl    = var.s3_bucket_acl["dq_asn_marine_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_asn_marine_internal/"
  }

  tags = {
    Name = "s3-dq-asn-marine-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_asn_marine_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_asn_marine_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_asn_marine_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_asn_marine_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_asn_marine_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_asn_marine_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_asn_marine_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_asn_marine_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_asn_marine_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_asn_marine_internal_bucket]

}

resource "aws_s3_bucket_metric" "dq_asn_marine_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_asn_marine_internal"]
  name   = "dq_asn_marine_internal_metric"
}

resource "aws_s3_bucket" "dq_rm_archive_bucket" {
  bucket = var.s3_bucket_name["dq_rm_archive"]
  acl    = var.s3_bucket_acl["dq_rm_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_rm_archive/"
  }

  tags = {
    Name = "s3-dq-rm-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_rm_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_rm_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_rm_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_rm_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_rm_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_rm_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_rm_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_rm_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_rm_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_rm_archive_bucket]

}

resource "aws_s3_bucket_metric" "dq_rm_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_rm_archive"]
  name   = "dq_rm_archive_metric"
}

resource "aws_s3_bucket" "dq_rm_internal_bucket" {
  bucket = var.s3_bucket_name["dq_rm_internal"]
  acl    = var.s3_bucket_acl["dq_rm_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_rm_internal/"
  }

  tags = {
    Name = "s3-dq-rm-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_rm_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_rm_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_rm_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_rm_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_rm_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_rm_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_rm_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_rm_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_rm_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_rm_internal_bucket]

}

resource "aws_s3_bucket_metric" "dq_rm_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_rm_internal"]
  name   = "dq_rm_internal_metric"
}

resource "aws_s3_bucket" "dq_data_generator_bucket" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["dq_data_generator"]
  acl    = var.s3_bucket_acl["dq_data_generator"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_data_generator/"
  }

  tags = {
    Name = "s3-dq-data-generator-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_data_generator_bucket_versioning" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.dq_data_generator_bucket[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_data_generator_bucket_server_side_encryption_configuration" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.dq_data_generator_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_data_generator_bucket_pub_block" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.dq_data_generator_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_data_generator_bucket_policy" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["dq_data_generator"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_data_generator"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_data_generator_bucket]

}

resource "aws_s3_bucket_metric" "dq_data_generator_bucket_logging" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = var.s3_bucket_name["dq_data_generator"]
  name   = "dq_data_generator_metric"
}

#######
# AIS
#######

resource "aws_s3_bucket" "dq_ais_archive_bucket" {
  bucket = var.s3_bucket_name["dq_ais_archive"]
  acl    = var.s3_bucket_acl["dq_ais_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_ais_archive/"
  }

  tags = {
    Name = "s3-dq-dq-ais-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_ais_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_ais_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_ais_archive_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_ais_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_ais_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_ais_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_ais_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_ais_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_ais_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_metric" "dq_ais_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_ais_archive"]
  name   = "dq_ais_archive_metric"
}

resource "aws_s3_bucket" "dq_ais_internal_bucket" {
  bucket = var.s3_bucket_name["dq_ais_internal"]
  acl    = var.s3_bucket_acl["dq_ais_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_ais_internal/"
  }

  tags = {
    Name = "s3-dq-ais-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_ais_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_ais_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_ais_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_ais_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_ais_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_ais_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_ais_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_ais_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_ais_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_ais_internal_bucket]

}

resource "aws_s3_bucket_metric" "dq_ais_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_ais_internal"]
  name   = "dq_ais_internal_metric"
}

########
# GAIT Landing STG
#########

resource "aws_s3_bucket" "dq_gait_landing_staging_bucket" {
  count  = var.namespace == "notprod" ? 0 : 1
  bucket = var.s3_bucket_name["dq_gait_landing_staging"]
  acl    = var.s3_bucket_acl["dq_gait_landing_staging"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_gait_landing_staging/"
  }

  tags = {
    Name = "s3-dq-gait-landing-staging"
  }
}

resource "aws_s3_bucket_versioning" "dq_gait_landing_staging_bucket_versioning" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.dq_gait_landing_staging_bucket[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_gait_landing_staging_bucket_server_side_encryption_configuration" {
  count  = var.namespace == "notprod" ? 1 : 0
  bucket = aws_s3_bucket.dq_gait_landing_staging_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dq_gait_landing_staging_bucket_policy" {
  count  = var.namespace == "notprod" ? 0 : 1
  bucket = var.s3_bucket_name["dq_gait_landing_staging"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_gait_landing_staging"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_gait_landing_staging_bucket]

}

resource "aws_s3_bucket_metric" "dq_gait_landing_staging_bucket_logging" {
  count  = var.namespace == "notprod" ? 0 : 1
  bucket = var.s3_bucket_name["dq_gait_landing_staging"]
  name   = "dq_gait_landing_staging_metric"
}

resource "aws_s3_bucket" "dq_pnr_archive_bucket" {
  bucket = var.s3_bucket_name["dq_pnr_archive"]
  acl    = var.s3_bucket_acl["dq_pnr_archive"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_pnr_archive/"
  }

  tags = {
    Name = "s3-dq-pnr-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_pnr_archive_bucket_versioning" {
  bucket = aws_s3_bucket.dq_pnr_archive_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_pnr_archive_bucket_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_pnr_archive_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_pnr_archive_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_pnr_archive_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_pnr_archive_bucket_policy" {
  bucket = var.s3_bucket_name["dq_pnr_archive"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_pnr_archive"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_pnr_archive_bucket]

}

resource "aws_s3_bucket_metric" "dq_pnr_archive_bucket_logging" {
  bucket = var.s3_bucket_name["dq_pnr_archive"]
  name   = "dq_pnr_archive_metric"
}

resource "aws_s3_bucket" "dq_pnr_internal_bucket" {
  bucket = var.s3_bucket_name["dq_pnr_internal"]
  acl    = var.s3_bucket_acl["dq_pnr_internal"]

  # versioning {
  #  enabled = true
  # }

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      sse_algorithm = "AES256"
  #    }
  #  }
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "dq_pnr_internal/"
  }

  tags = {
    Name = "s3-dq-pnr-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_versioning" "dq_pnr_internal_bucket_versioning" {
  bucket = aws_s3_bucket.dq_pnr_internal_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dq_pnr_internal_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.dq_pnr_internal_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dq_pnr_internal_bucket_pub_block" {
  bucket = aws_s3_bucket.dq_pnr_internal_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "dq_pnr_internal_bucket_policy" {
  bucket = var.s3_bucket_name["dq_pnr_internal"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["dq_pnr_internal"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.dq_pnr_internal_bucket]

}

resource "aws_s3_bucket_metric" "dq_pnr_internal_bucket_logging" {
  bucket = var.s3_bucket_name["dq_pnr_internal"]
  name   = "dq_pnr_internal_metric"
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.appsvpc.id
  route_table_ids = [aws_route_table.apps_route_table.id]
  service_name    = "com.amazonaws.eu-west-2.s3"
}

resource "aws_s3_bucket" "carrier_portal_docs" {
  bucket = var.s3_bucket_name["carrier_portal_docs"]
  acl    = var.s3_bucket_acl["carrier_portal_docs"]
  # region = var.region

  # server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = aws_kms_key.bucket_key.arn
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  # }

  # versioning {
  #   enabled = true
  # }

  logging {
    target_bucket = aws_s3_bucket.log_archive_bucket.id
    target_prefix = "carrier_portal_docs/"
  }

  # lifecycle_rule {
  #  enabled = true
  #  transition {
  #    days          = 30
  #    storage_class = "STANDARD_IA"
  #  }
  #  noncurrent_version_transition {
  #    noncurrent_days = 30
  #    storage_class   = "STANDARD_IA"
  #  }
  # }

  tags = {
    Name = "s3-dq-carrier-portal-docs-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "carrier_portal_docs-config" {
  bucket = aws_s3_bucket.carrier_portal_docs.id

  rule {
    id = "carrier_portal_docs_config"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "carrier_portal_docs_versioning" {
  bucket = aws_s3_bucket.carrier_portal_docs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "carrier_portal_docs_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.carrier_portal_docs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "carrier_portal_docs_pub_block" {
  bucket = aws_s3_bucket.carrier_portal_docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "carrier_portal_docs" {
  bucket = var.s3_bucket_name["carrier_portal_docs"]

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "arn:aws:s3:::${var.s3_bucket_name["carrier_portal_docs"]}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_s3_bucket.carrier_portal_docs]

}

resource "aws_s3_bucket_metric" "carrier_portal_docs_logging" {
  bucket = var.s3_bucket_name["carrier_portal_docs"]
  name   = "dq_carrier_portal_docs_metric"
}