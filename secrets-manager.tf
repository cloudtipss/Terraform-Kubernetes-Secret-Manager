resource "aws_secretsmanager_secret" "db_secret" {
  name = "db-secret"
}

data "aws_caller_identity" "current" {}

# Create a Secrets Manager resource policy that allows access to the secret only for the 'ping-role'
resource "aws_secretsmanager_secret_policy" "ping_secret_policy" {
  secret_arn = aws_secretsmanager_secret.db_secret.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PingRoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ping-role"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = aws_secretsmanager_secret.ping_secret.arn
      }
    ]
  })
}