apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${service_account}
  namespace: ${namespace}
  labels:
    app: cryptospins-api
    managed-by: terraform
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::269599744150:role/${cluster_name}-app-service-role
automountServiceAccountToken: true

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cryptospins-app-role
  labels:
    managed-by: terraform
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets", "services", "endpoints"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cryptospins-app-binding
  labels:
    managed-by: terraform
subjects:
- kind: ServiceAccount
  name: ${service_account}
  namespace: ${namespace}
roleRef:
  kind: ClusterRole
  name: cryptospins-app-role
  apiGroup: rbac.authorization.k8s.io