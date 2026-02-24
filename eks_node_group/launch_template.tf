locals {

  base_user_data = <<-EOF
%{ if var.node_group_properties["name"] == "gpu-worker" }
Content-Type: application/node.eks.aws; charset="us-ascii"
#!/bin/bash

echo "$(jq '.healthzBindAddress="0.0.0.0"' /etc/kubernetes/kubelet/kubelet-config.json)" > /etc/kubernetes/kubelet/kubelet-config.json
mkdir /var/log/pplogger
sudo chown -R 1000:000 /var/log/pplogger
%{ else }
Content-Type: application/node.eks.aws; charset="us-ascii"

  apiVersion: node.eks.aws/v1alpha1
  kind: NodeConfig
  spec:
    kubelet:
      config:
        healthzBindAddress: "0.0.0.0"
        registryPullQPS: 50
--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
mkdir /var/log/pplogger
sudo chown -R 1000:000 /var/log/pplogger
%{ endif }
EOF

  user_data_suffix =<<EOF
${var.node_group_properties["user_data_suffix"]}
--//
EOF

  user_data =<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//

${local.base_user_data}
${trimspace(local.user_data_suffix)}

EOF

  default_block_device_mappings = {
    rootEBS = {
      device_name = "/dev/xvda"
      ebs = {
          iops = 3000
          throughput = 128
          volume_size = 80
      }
    }
  }
  default_tags = {
    Name = "eks-node-group/${var.node_group_properties["name"]}"
    monitoring = "True"
    sub-product = "eks-nodes"
  }
}

resource aws_launch_template "launch-template" {
  user_data =  "${base64encode(local.user_data)}"
  vpc_security_group_ids = concat([var.eks_node_sg], var.node_group_properties["extra_eks_node_sgs"])
  update_default_version = true
  metadata_options {
    http_protocol_ipv6 = "disabled"
    http_put_response_hop_limit = 2
    http_tokens = coalesce(try(var.node_group_properties["imdsv2_enabled"], null), true)? "required" : "optional"
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.default_tags, var.node_group_properties["tags"])
  }

  dynamic "block_device_mappings" {
    for_each = coalesce(var.node_group_properties["block_device_mappings"], local.default_block_device_mappings)
    content {
      device_name = block_device_mappings.value["device_name"]
      ebs {
        volume_type = "gp3"
        encrypted = true
        delete_on_termination = true
        iops = block_device_mappings.value["ebs"]["iops"]
        throughput = block_device_mappings.value["ebs"]["throughput"]
        volume_size = block_device_mappings.value["ebs"]["volume_size"]
      }
    }
  }
}
