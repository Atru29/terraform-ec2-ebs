# Última AMI de Amazon Linux 2023, publicada por AWS en Parameter Store.
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Subred por defecto de la AZ elegida, en la VPC por defecto.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = var.availability_zone
  default_for_az    = true
}

# SSH solo para entrar con EC2 Instance Connect (sin key pair).
resource "aws_security_group" "ssh" {
  name_prefix = "ec2-ebs-ssh-"
  description = "SSH para EC2 Instance Connect"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Paso 1: la EC2.
resource "aws_instance" "lab" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "ec2-ebs-lab"
  }
}

# Paso 1: volumen EBS adicional gp3, en la MISMA AZ que la EC2.
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.lab.availability_zone
  size              = var.data_volume_size
  type              = "gp3"

  tags = {
    Name = "ec2-ebs-data"
  }
}

# Paso 2: adjuntar el volumen. En instancias Nitro (t3) aparece como /dev/nvme1n1.
resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.lab.id
}
