# Fase 2 (create_snapshot = true): snapshot del volumen de datos
# y restauración en un volumen INDEPENDIENTE, adjuntado como segundo disco.

resource "aws_ebs_snapshot" "data" {
  count     = var.create_snapshot ? 1 : 0
  volume_id = aws_ebs_volume.data.id

  tags = {
    Name = "ec2-ebs-data-snapshot"
  }
}

resource "aws_ebs_volume" "restored" {
  count             = var.create_snapshot ? 1 : 0
  availability_zone = aws_instance.lab.availability_zone
  snapshot_id       = aws_ebs_snapshot.data[0].id
  type              = "gp3"

  tags = {
    Name = "ec2-ebs-restored"
  }
}

resource "aws_volume_attachment" "restored" {
  count       = var.create_snapshot ? 1 : 0
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.restored[0].id
  instance_id = aws_instance.lab.id
}
