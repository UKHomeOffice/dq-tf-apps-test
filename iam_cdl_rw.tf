resource "aws_iam_group" "cdl_user_group_rw" {
  name = "iam-group-cdl-rw-${local.naming_suffix}"
}

resource "aws_iam_group_membership" "cdl_user_group_rw" {
  name = "iam-group-membership-cdl-rw-${local.naming_suffix}"

  users = [
    "${aws_iam_user.cdl_user_rw.name}",
  ]

  group = aws_iam_group.cdl_user_group_rw.name
}

resource "aws_iam_group_policy" "cdl_user_rw" {
  name  = "iam-group-policy-cdl-rw-${local.naming_suffix}"
  group = aws_iam_group.cdl_user_group_rw.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "${aws_s3_bucket.cdl_s3_s4_parsed.arn}",
        "${aws_s3_bucket.cdl_s3_s4_parsed.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.cdl_s3_s4_parsed.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
        ],
      "Resource": "${aws_kms_key.bucket_key.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user" "cdl_user_rw" {
  name = "iam-user-cdl-rw-${local.naming_suffix}"
}

resource "aws_iam_access_key" "cdl_user_rw" {
  user  = aws_iam_user.cdl_user_rw.name
}

resource "aws_ssm_parameter" "cdl_user_id_rw" {
  name  = "cdl-user-id-rw${local.naming_suffix}"
  type  = "SecureString"
  value = aws_iam_access_key.cdl_user_rw.id
}

resource "aws_ssm_parameter" "cdl_user_key_rw" {
  name  = "cdl-user-key-rw-${local.naming_suffix}"
  type  = "SecureString"
  value = aws_iam_access_key.cdl_user_rw.secret
}
