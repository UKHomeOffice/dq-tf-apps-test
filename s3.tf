resource "aws_kms_key" "bucket_key" {
  description             = "This key is used to encrypt APPS buckets"
  deletion_window_in_days = 7

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
  bucket = "${var.s3_bucket_name["archive_log"]}"
  acl    = "${var.s3_bucket_acl["archive_log"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = {
    Name = "s3-log-archive-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_metric" "log_archive_bucket_logging" {
  bucket = "${var.s3_bucket_name["archive_log"]}"
  name   = "log_archive_bucket_metric"
}

resource "aws_s3_bucket" "data_archive_bucket" {
  bucket = "${var.s3_bucket_name["archive_data"]}"
  acl    = "${var.s3_bucket_acl["archive_data"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "data_archive_bucket/"
  }

  tags = {
    Name = "s3-data-archive-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_metric" "data_archive_bucket_logging" {
  bucket = "${var.s3_bucket_name["archive_data"]}"
  name   = "data_archive_bucket_metric"
}

resource "aws_s3_bucket" "data_working_bucket" {
  bucket = "${var.s3_bucket_name["working_data"]}"
  acl    = "${var.s3_bucket_acl["working_data"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "data_working_bucket/"
  }

  tags = {
    Name = "s3-data-working-bucket-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_metric" "data_working_bucket_logging" {
  bucket = "${var.s3_bucket_name["working_data"]}"
  name   = "data_working_bucket_metric"
}

resource "aws_s3_bucket" "oag_archive_bucket" {
  bucket = "${var.s3_bucket_name["oag_archive"]}"
  acl    = "${var.s3_bucket_acl["oag_archive"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "oag_archive_bucket/"
  }

  tags = {
    Name = "s3-dq-oag-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "acl_archive_bucket" {
  bucket = "${var.s3_bucket_name["acl_archive"]}"
  acl    = "${var.s3_bucket_acl["acl_archive"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "acl_archive_bucket/"
  }

  tags = {
    Name = "s3-dq-acl-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "reference_data_bucket" {
  bucket = "${var.s3_bucket_name["reference_data"]}"
  acl    = "${var.s3_bucket_acl["reference_data"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "reference_data_bucket/"
  }

  tags = {
    Name = "s3-dq-reference-data-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "reference_data_archive_bucket" {
  bucket = "${var.s3_bucket_name["reference_data_archive"]}"
  acl    = "${var.s3_bucket_acl["reference_data_archive"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "reference_data_archive_bucket/"
  }

  tags = {
    Name = "s3-dq-reference-data-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "reference_data_internal_bucket" {
  bucket = "${var.s3_bucket_name["reference_data_internal"]}"
  acl    = "${var.s3_bucket_acl["reference_data_internal"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "reference_data_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-reference-data-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "api_archive_bucket" {
  bucket = "${var.s3_bucket_name["api_archive"]}"
  acl    = "${var.s3_bucket_acl["api_archive"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "api_archive_bucket/"
  }

  tags = {
    Name = "s3-dq-api-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "airports_archive_bucket" {
  bucket = "${var.s3_bucket_name["airports_archive"]}"
  acl    = "${var.s3_bucket_acl["airports_archive"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "airports_archive_bucket/"
  }

  tags = {
    Name = "s3-dq-airports-archive-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket_policy" "airports_archive_policy" {
  bucket = "${var.s3_bucket_name["airports_archive"]}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "DENYHTTP",
  "Statement": [
    {
      "Sid": "HTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "*",
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
  bucket = "${var.s3_bucket_name["oag_internal"]}"
  acl    = "${var.s3_bucket_acl["oag_internal"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "oag_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-oag-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "oag_transform_bucket" {
  bucket = "${var.s3_bucket_name["oag_transform"]}"
  acl    = "${var.s3_bucket_acl["oag_transform"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "oag_transform_bucket/"
  }

  tags = {
    Name = "s3-dq-oag-transform-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "acl_internal_bucket" {
  bucket = "${var.s3_bucket_name["acl_internal"]}"
  acl    = "${var.s3_bucket_acl["acl_internal"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "acl_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-acl-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "api_internal_bucket" {
  bucket = "${var.s3_bucket_name["api_internal"]}"
  acl    = "${var.s3_bucket_acl["api_internal"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "api_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-api-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "airports_internal_bucket" {
  bucket = "${var.s3_bucket_name["airports_internal"]}"
  acl    = "${var.s3_bucket_acl["airports_internal"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "airports_internal_bucket/"
  }

  tags = {
    Name = "s3-dq-airports-internal-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "consolidated_schedule_bucket" {
  bucket = "${var.s3_bucket_name["consolidated_schedule"]}"
  acl    = "${var.s3_bucket_acl["consolidated_schedule"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "consolidated_schedule_bucket/"
  }

  tags = {
    Name = "s3-dq-consolidated-schedule-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "api_record_level_scoring_bucket" {
  bucket = "${var.s3_bucket_name["api_record_level_scoring"]}"
  acl    = "${var.s3_bucket_acl["api_record_level_scoring"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "api_record_level_scoring_bucket/"
  }

  tags = {
    Name = "s3-dq-api-record-level-scoring-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "raw_file_retrieval_index_bucket" {
  bucket = "${var.s3_bucket_name["raw_file_retrieval_index"]}"
  acl    = "${var.s3_bucket_acl["raw_file_retrieval_index"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "raw_file_retrival_index_bucket/"
  }

  tags = {
    Name = "s3-dq-raw-file-retrieval-index-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "cross_record_scored_bucket" {
  bucket = "${var.s3_bucket_name["cross_record_scored"]}"
  acl    = "${var.s3_bucket_acl["cross_record_scored"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "cross_record_scored_bucket/"
  }

  tags = {
    Name = "s3-dq-cross-record-scored-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "drt_working_bucket" {
  bucket = "${var.s3_bucket_name["drt_working"]}"
  acl    = "${var.s3_bucket_acl["drt_working"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "drt_working_bucket/"
  }

  tags = {
    Name = "s3-dq-drt-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "fms_working_bucket" {
  bucket = "${var.s3_bucket_name["fms_working"]}"
  acl    = "${var.s3_bucket_acl["fms_working"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "fms_working_bucket/"
  }

  tags = {
    Name = "s3-dq-fms-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "airports_working_bucket" {
  bucket = "${var.s3_bucket_name["airports_working"]}"
  acl    = "${var.s3_bucket_acl["airports_working"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "airports_working_bucket/"
  }

  tags = {
    Name = "s3-dq-airports-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "reporting_internal_working_bucket" {
  bucket = "${var.s3_bucket_name["reporting_internal_working"]}"
  acl    = "${var.s3_bucket_acl["reporting_internal_working"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "reporting_internal_working_bucket/"
  }

  tags = {
    Name = "s3-dq-reporting-internal-working-${local.naming_suffix}"
  }
}

resource "aws_s3_bucket" "carrier_portal_working_bucket" {
  bucket = "${var.s3_bucket_name["carrier_portal_working"]}"
  acl    = "${var.s3_bucket_acl["carrier_portal_working"]}"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_archive_bucket.id}"
    target_prefix = "carrier_portal_working_bucket/"
  }

  tags = {
    Name = "s3-dq-carrier-portal-working-${local.naming_suffix}"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = "${aws_vpc.appsvpc.id}"
  route_table_ids = ["${aws_route_table.apps_route_table.id}"]
  service_name    = "com.amazonaws.eu-west-2.s3"
}
