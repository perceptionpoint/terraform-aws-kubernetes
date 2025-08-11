locals {
  base_user_data =<<EOF
echo "$(jq '.healthzBindAddress="0.0.0.0"' /etc/kubernetes/kubelet/kubelet-config.json)" > /etc/kubernetes/kubelet/kubelet-config.json
mkdir /var/log/pplogger
sudo chown -R 1000:000 /var/log/pplogger
mkfs -t xfs  /dev/xvdb
mkdir /filebeat-queue
mount /dev/xvdb /filebeat-queue
EOF

  user_data_suffix =<<EOF
${var.node_group_properties["user_data_suffix"]}
--//
EOF

  user_data =<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
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
    pplogger = {
      device_name = "/dev/xvdb"
      ebs = {
          iops = 500
          throughput = 128
          volume_size = 30
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
