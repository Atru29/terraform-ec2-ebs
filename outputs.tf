output "instance_id" {
  value = aws_instance.lab.id
}

output "availability_zone" {
  value = aws_instance.lab.availability_zone
}

output "public_ip" {
  value = aws_instance.lab.public_ip
}

output "data_volume_id" {
  description = "En lsblk aparece como SERIAL sin el guion (vol0abc...)"
  value       = aws_ebs_volume.data.id
}

output "snapshot_id" {
  value = var.create_snapshot ? aws_ebs_snapshot.data[0].id : null
}

output "restored_volume_id" {
  value = var.create_snapshot ? aws_ebs_volume.restored[0].id : null
}

output "connect_command" {
  value = "aws ec2-instance-connect ssh --instance-id ${aws_instance.lab.id} --region ${var.region}"
}
