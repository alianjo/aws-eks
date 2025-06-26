output "instance_id" {
  value = aws_instance.ali.id
}

output "instance_public_ip" {
  value = aws_eip.ali-eip.public_ip
}

output "instance_private_ip" {
  value = aws_instance.ali.private_ip
}

output "instance_public_dns" {
  value = aws_eip.ali-eip.public_dns
}

output "instance_private_dns" {
  value = aws_instance.ali.private_dns
}
