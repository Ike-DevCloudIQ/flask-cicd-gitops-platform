output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "private_subnet_id" {
  value = module.network.private_subnet_id
}

output "internet_gateway_id" {
  value = module.network.internet_gateway_id
}

output "nat_gateway_id" {
  value = module.network.nat_gateway_id
}

output "jenkins_master_sg_id" {
  value = module.security.jenkins_master_sg_id
}

output "jenkins_slave_sg_id" {
  value = module.security.jenkins_slave_sg_id
}

output "jenkins_master_public_ip" {
  description = "Use this IP in your Ansible inventory for Jenkins master"
  value       = module.compute.jenkins_master_public_ip
}

output "jenkins_slave_private_ip" {
  description = "Use this IP in your Ansible inventory for Jenkins slave"
  value       = module.compute.jenkins_slave_private_ip
}

output "ami_id_used" {
  value = module.compute.ami_id_used
}

output "sns_topic_arn" {
  value = module.notifications.sns_topic_arn
}
