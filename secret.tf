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
      - objectName: "arn:aws:secretsmanager:us-east-1:803253357612:secret:db-secret-pCgK81"
        jmesPath:
            - path: "password"
              objectAlias: "MySecretPassword"
YAML
}


