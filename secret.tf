resource "helm_release" "secret-store" {
  name      = "secrets-store"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"

  set {
    name  = "syncSecret.enabled"
    value = true
  }

  set {
    name  = "enableSecretRotation"
    value = true
  }

#   values = [
#     file("${path.module}/secret-store-files/values.yaml")
#   ]
}
resource "helm_release" "aws_secrets_provider" {
  name      = "aws-secrets-provider"
  namespace = "kube-system"

  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
}
resource "kubernetes_service_account" "csi-aws" {
  metadata {
    name      = "csi-secrets-store-provider-aws"
    namespace = "kube-system"
  }
}


###ADDED
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    condition {
      test = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:default:ping-sa"]
    }

    principals {
      identifiers = [
        module.eks.oidc_provider_arn]
      type = "Federated"
    }
  }
}

resource "aws_iam_role" "ping_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name = "ping-role"
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
  role = aws_iam_role.ping_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "kubectl_manifest" "secret-class" {
  depends_on = [module.eks]

  yaml_body = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1  
kind: SecretProviderClass
metadata:
  name: secret
spec:
  provider: aws
  secretObjects:
    - secretName: databasepassword
      type: Opaque
      data:
        - objectName: "MySecretPassword"
          key: password
  parameters:
    objects: |
      - objectName: "arn:aws:secretsmanager:us-east-1:803253357612:secret:ping-secret-12345-ONWk14"
        jmesPath:
            - path: "password"
              objectAlias: "MySecretPassword"
YAML
}

