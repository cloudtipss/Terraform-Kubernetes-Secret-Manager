# Create unique secret name in your account
resource "aws_secretsmanager_secret" "db_secret" {
  name = "db-secret"
}

#Update key and a value as needed {"password": "12345"}
resource "null_resource" "set_secret_value" {
  triggers = {
    secret_id = aws_secretsmanager_secret.db_secret.id
  }

  provisioner "local-exec" {
    command = <<EOT
      aws secretsmanager put-secret-value --secret-id ${aws_secretsmanager_secret.db_secret.id} --secret-string '{"password": "12345"}'
    EOT
  }
}



data "aws_caller_identity" "current" {}

# Create a Secrets Manager resource policy that allows access to the secret only for the 'secret-role'
resource "aws_secretsmanager_secret_policy" "db_secret_policy" {
  secret_arn = aws_secretsmanager_secret.db_secret.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretRoleAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.secret_role.name}"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}