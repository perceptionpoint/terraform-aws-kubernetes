output "eks_vpc_cni_role_arn" {
    value = aws_iam_role.eks-vpc-cni-role.arn
}

output "eks_ebs_csi_driver_role_arn" {
    value = aws_iam_role.eks-ebs-csi-driver-role.arn
}
