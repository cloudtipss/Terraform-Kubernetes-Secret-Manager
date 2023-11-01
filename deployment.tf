resource "kubectl_manifest" "test_deployment" {
  depends_on = [module.eks, kubectl_manifest.secrets-sa, aws_secretsmanager_secret.db_secret]

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - image: nginx
        name: test-app
        volumeMounts:
        - name: secret-volume
          mountPath: "/var/run/secrets/db-secret"
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: databasepassword 
              key: password
      serviceAccountName: secrets-sa
      volumes:
      - name: secret-volume
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            objectVersion: AWSCURRENT
            secretProviderClass: secret
YAML
}

resource "kubectl_manifest" "secrets-sa" {
  depends_on = [module.eks]

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secrets-sa
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.secret_role.arn}
automountServiceAccountToken: true
secrets:
- name: token
YAML
}
