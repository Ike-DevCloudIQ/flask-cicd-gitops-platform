output "jenkins_master_sg_id" {
  description = "Security group ID for Jenkins master"
  value       = aws_security_group.jenkins_master.id
}

output "jenkins_slave_sg_id" {
  description = "Security group ID for Jenkins slave"
  value       = aws_security_group.jenkins_slave.id
}
