output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins master (used by Ansible inventory)"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_master_instance_id" {
  description = "Instance ID of Jenkins master"
  value       = aws_instance.jenkins_master.id
}

output "jenkins_slave_private_ip" {
  description = "Private IP of Jenkins slave (used by Ansible dynamic inventory)"
  value       = aws_instance.jenkins_slave.private_ip
}

output "jenkins_slave_instance_id" {
  description = "Instance ID of Jenkins slave"
  value       = aws_instance.jenkins_slave.id
}

output "ami_id_used" {
  description = "Amazon Linux 2023 AMI ID resolved at apply time"
  value       = data.aws_ami.amazon_linux_2023.id
}
