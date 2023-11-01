#Create a Kubernetes service account called 'ping-sa' that is linked to the 'ping-role' IAM role & a Kubernetes deployment that is associated with the 'ping-sa' service account
resource "kubectl_manifest" "ping_deployment" {
  depends_on = [module.eks, kubectl_manifest.ping-sa]

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ping-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ping
  template:
    metadata:
      labels:
        app: ping
    spec:
      containers:
      - image: nginx:1.21
        name: ping
        volumeMounts:
        - name: secret-volume
          mountPath: "/var/run/secrets/ping-secret"
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: databasepassword 
              key: password
      serviceAccountName: ping-sa
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

resource "kubectl_manifest" "ping-sa" {
  depends_on = [module.eks]

  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ping-sa
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.ping_role.arn}
automountServiceAccountToken: true
secrets:
- name: token
YAML
}

# apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
# kind: SecretProviderClass
# metadata:
#   name: nginx-deployment-aws-secrets
# spec:
#   provider: aws
#   parameters:
#     objects: |
#         - objectName: "ping-secret-1234"
#           objectType: "secretsmanager"
# ---            
# kind: Service
# apiVersion: v1
# metadata:
#   name: nginx-deployment
#   labels:
#     app: nginx
# spec:
#   selector:
#     app: nginx
#   ports:
#     - protocol: TCP
#       port: 80
#       targetPort: 80
# ---  