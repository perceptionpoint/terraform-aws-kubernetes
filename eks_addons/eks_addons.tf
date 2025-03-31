module "security" {
  source = "./security"

  eks_cluster_name = var.eks_cluster_name
  oidc_provider = var.oidc_provider
}

resource "aws_eks_addon" "eks_addon" {
  for_each = local.core_addon_properties

  cluster_name = var.eks_cluster_name
  addon_name = each.key
  addon_version = each.value["addon_version"]
  configuration_values = try(each.value["configuration_values"], null)
  service_account_role_arn = try(each.value["service_account_role_arn"], null)
  resolve_conflicts_on_create = coalesce(try(each.value["resolve_conflicts_on_create"], null), "OVERWRITE")
  resolve_conflicts_on_update = coalesce(try(each.value["resolve_conflicts_on_update"], null), "OVERWRITE")

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  core_addon_properties = {
    vpc-cni = {
      addon_version = coalesce(try(var.core_addon_properties["vpc-cni"]["addon_version"], null), "v1.18.3-eksbuild.3")
      service_account_role_arn = module.security.eks_vpc_cni_role_arn
      configuration_values = jsonencode({
        init = {
          env = {
            DISABLE_TCP_EARLY_DEMUX = "true"
          }
        }
        env = {
          DISABLE_POD_V6 = "true"
        }
        podAnnotations = {
          "prometheus.io/port" = "61678",
          "prometheus.io/scrape" = "true"
        }
      })
    }
    kube-proxy = {
      addon_version = coalesce(try(var.core_addon_properties["kube-proxy"]["addon_version"], null), "v1.29.7-eksbuild.9")
    }
    aws-ebs-csi-driver = {
      addon_version = coalesce(try(var.core_addon_properties["aws-ebs-csi-driver"]["addon_version"], null), "v1.35.0-eksbuild.1")
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn = module.security.eks_ebs_csi_driver_role_arn
      configuration_values = jsonencode({
        controller = {
          tolerations = [
            {
              effect = "NoSchedule"
              key = "perception-point.io/system-critical"
              operator = "Exists"
            },
            {
              key = "CriticalAddonsOnly"
              operator = "Exists"
            },
            {
              effect = "NoExecute"
              operator = "Exists"
              tolerationSeconds = 300
            }
          ]
          nodeSelector = {
            componentType = "system-critical"
          }
        }
      })
    }
    coredns = {
      addon_version = coalesce(try(var.core_addon_properties["coredns"]["addon_version"], null), "v1.11.3-eksbuild.1")
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode({
        tolerations = [
          {
            effect = "NoSchedule"
            key = "perception-point.io/coredns"
            operator = "Exists"
          },
          {
            effect = "NoSchedule"
            key = "node-role.kubernetes.io/control-plane"
          },
          {
            effect = "NoSchedule"
            key = "node-role.kubernetes.io/master"
          },
          {
            key = "CriticalAddonsOnly"
            operator = "Exists"
          }
        ]
        nodeSelector = {
          componentType = "coredns"
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution	= []
            requiredDuringSchedulingIgnoredDuringExecution	= [{
              labelSelector = {
                matchExpressions = [{
                  key = "k8s-app"
                  operator = "In"
                  values = ["kube-dns"]
                }]
              }
              topologyKey = "kubernetes.io/hostname"
            }]
          }
        }
        resources = {
          requests = {
            cpu = "200m"
            memory = "100Mi"
          }
          limits = {
            cpu = "200m"
            memory = "100Mi"
          }
        }
        podDisruptionBudget = {
          enabled = true
          maxUnavailable = 1
        }
        replicaCount = var.core_addon_properties["coredns"]["configuration_values"]["replicaCount"]
        corefile =<<COREFILE
          .:53 {
            errors
            log {
              class denial
              class error
            }
            health {
              lameduck 30s
            }
            ready
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 900
            loop
            reload
            loadbalance
          }
        COREFILE
      })
    }
  }
}
