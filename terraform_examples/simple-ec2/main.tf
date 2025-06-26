resource "aws_instance" "ali" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ali-sg.id]
  tags = {
    Name       = var.instance_name
    Created_By = "terraform"
  }
}

resource "aws_security_group" "ali-sg" {
  name        = "instance-sg"
  description = "Security group for ali"

  ingress {
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

resource "aws_key_pair" "ali-key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_eip" "ali-eip" {
  instance = aws_instance.ali.id
  vpc      = true
}

resource "aws_eip_association" "eip-assoc" {
  instance_id   = aws_instance.ali.id
  allocation_id = aws_eip.ali-eip.id
}
