resource "aws_ses_email_identity" "ses_email" {
  count = var.enable_ses ? 1 : 0
  email = var.ses_email
}

resource "aws_iam_access_key" "ses_key" {
  count = var.enable_ses ? 1 : 0
  user  = aws_iam_user.ses_user.0.name
}

resource "aws_iam_user" "ses_user" {
  count = var.enable_ses ? 1 : 0
  name  = "${var.namespace}-ses-user"
}

resource "aws_iam_user_policy" "ses_user_policy" {
  count  = var.enable_ses ? 1 : 0
  name   = "${var.namespace}-ses-user-policy"
  user   = aws_iam_user.ses_user.0.name
  policy = data.aws_iam_policy_document.ses_user_policy.0.json
}

data "aws_iam_policy_document" "ses_user_policy" {
  count = var.enable_ses ? 1 : 0
  statement {
    actions = [
      "ses:SendRawEmail",
    ]
    resources = ["*"]
  }
}
