resource "aws_iam_user" "gen-s3events-triggerlambda" {
  name = "gen-s3events-triggerlambda_user"
}


resource "aws_iam_access_key" "gen-s3events-triggerlambda" {
  user = aws_iam_user.gen-s3events-triggerlambda.name
}

resource "aws_iam_group" "gen-s3events-triggerlambda" {
  name = "gen-s3events-triggerlambda"
}

resource "aws_iam_group_policy" "gen-s3events-triggerlambda_policy" {
  name  = "gen-s3events-triggerlambda_policy"
  group = "${aws_iam_group.gen-s3events-triggerlambda.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:lambda:eu-west-2:797728447925:function:api-kafka-input-test-trigger"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group_membership" "gen-s3events-triggerlambda" {
  name = "gen-s3events-triggerlambda"

  users = [aws_iam_user.gen-s3events-triggerlambda.name]

  group = aws_iam_group.gen-s3events-triggerlambda.name
}
