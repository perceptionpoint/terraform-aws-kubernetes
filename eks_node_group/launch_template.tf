locals {
  user_data =<<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
${var.node_group_properties["user_data"]}
--//

EOF
}

resource aws_launch_template "launch-template" {
  user_data =  "${base64encode(local.user_data)}"
  vpc_security_group_ids = [var.eks_node_sg]
  metadata_options {
    http_protocol_ipv6 = "disabled"
    http_put_response_hop_limit = 2
    http_tokens = var.node_group_properties["imdsv2_enabled"]? "required" : "optional"
  }
  dynamic "block_device_mappings" {
    for_each = var.node_group_properties["block_device_mappings"]
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
