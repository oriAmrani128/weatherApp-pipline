output "eks_cluster_id" {
  description = "The EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_endpoint" {
  description = "The EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "The security group ID attached to the EKS cluster"
  value       = aws_security_group.eks.id
}

output "argocd_url" {
  description = "URL for ArgoCD UI"
  value       = "http://${data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.hostname}"
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

data "kubernetes_secret" "argocd_admin_password" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

output "argocd_admin_password" {
  description = "ArgoCD Admin Password"
  value       = nonsensitive(data.kubernetes_secret.argocd_admin_password.data["password"])
  sensitive   = true
  depends_on  = [helm_release.argocd]
}
