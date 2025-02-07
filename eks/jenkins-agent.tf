resource "kubernetes_namespace" "jenkins_agents" {
  metadata {
    name = "jenkins-agents"
  }
}

resource "kubernetes_service_account" "jenkins_agent" {
  metadata {
    name      = "jenkins-agent"
    namespace = kubernetes_namespace.jenkins_agents.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "jenkins_agent" {
  metadata {
    name = "jenkins-agent-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "pods/log"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "jenkins_agent" {
  metadata {
    name = "jenkins-agent-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins_agent.metadata[0].name
    namespace = kubernetes_namespace.jenkins_agents.metadata[0].name
  }
} 

# Create a token explicitly
resource "kubernetes_secret" "jenkins_agent_token" {
  metadata {
    name      = "jenkins-agent-token"
    namespace = kubernetes_namespace.jenkins_agents.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.jenkins_agent.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Update the output to use the new token
output "jenkins_agent_token" {
  value     = kubernetes_secret.jenkins_agent_token.data["token"]
  sensitive = true
}