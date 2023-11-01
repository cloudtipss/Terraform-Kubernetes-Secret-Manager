data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    condition {
      test = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:default:secrets-sa"]
    }

    principals {
      identifiers = [
        module.eks.oidc_provider_arn]
      type = "Federated"
    }
  }
}

resource "aws_iam_role" "secret_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name = "secret-role"
}

resource "aws_iam_policy" "policy" {
  name = "aws-secrets-manager-policy-marks-eks-cluster"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["arn:*:secretsmanager:*:*:secret:*"]
    } ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role = aws_iam_role.secret_role.name
  policy_arn = aws_iam_policy.policy.arn
}