output "Bastion-ip" {
  value = aws_instance.bastion.public_ip
}
output "Jenkins-ip" {
  value = aws_instance.jenkins.public_ip
}
output "db-endpoint" {
  value = aws_db_instance.onlinebookstore.endpoint
}
output "Tomcat-ip" {
  value = aws_instance.tomcat.public_ip
}