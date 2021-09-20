#This User allows the certificate expiry script to access slack_notification_webhook on ssm

resource "aws_iam_policy" "analysis_proxy_user" {
  name = "analysis_proxy_user_policy"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts"
        ],
        "Effect": "Allow",
        "Resource": [
          "${aws_s3_bucket.data_archive_bucket.arn}"
        ]
      }
    ]
  }
EOF
}

resource "aws_iam_group_policy_attachment" "analysis_proxy_user" {
  group      = aws_iam_group.analysis_proxy_user.name
  policy_arn = aws_iam_policy.analysis_proxy_user.arn
}

resource "aws_iam_user" "analysis_proxy_user" {
  name = "analysis_proxy_user"
}


resource "aws_iam_access_key" "analysis_proxy_user" {
  user = aws_iam_user.analysis_proxy_user.name
}

resource "aws_iam_group" "analysis_proxy_user" {
  name = "analysis_proxy_user"
}

resource "aws_iam_group_membership" "analysis_proxy_user" {
  name = "analysis_proxy_user"

  users = [aws_iam_user.analysis_proxy_user.name]

  group = aws_iam_group.analysis_proxy_user.name
}

resource "aws_ssm_parameter" "analysis_proxy_user_id" {
  name  = "analysis-proxy-user-id-${local.naming_suffix}"
  type  = "SecureString"
  value = aws_iam_access_key.analysis_proxy_user.id
}

resource "aws_ssm_parameter" "analysis_proxy_user_key" {
  name  = "analysis-proxy-user-key-${local.naming_suffix}"
  type  = "SecureString"
  value = aws_iam_access_key.analysis_proxy_user.secret
}
