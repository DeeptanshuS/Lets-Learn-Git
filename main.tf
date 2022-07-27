provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "RDJ-TF-VPC" {
  cidr_block = var.cidr_block
  tags = {
    Name = "RDJ-TF-VPC"
  }
}
resource "aws_security_group" "RDJ-TF-SecG" {
  vpc_id = aws_vpc.RDJ-TF-VPC.id
  name = "RDJ-TF-SecG"
  description = "RDJ-TF-SecG"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDJ-TF-SecG"
  }
}
resource "aws_internet_gateway" "RDJ-TF-IGW" {
  vpc_id = aws_vpc.RDJ-TF-VPC.id

  tags = {
    Name = "RDJ-TF-IGW"
  }
}
resource "aws_subnet" "RDJ-TF-PublicSub" {
  vpc_id     = aws_vpc.RDJ-TF-VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "RDJ-TF-PublicSub"
  }
}
resource "aws_route_table" "RDJ-TF-PubRT" {
  vpc_id = aws_vpc.RDJ-TF-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.RDJ-TF-IGW.id
  }

  tags = {
    Name = "RDJ-TF-PubRT"
  }
}
resource "aws_route_table_association" "RDJ-TF-RTAsso" {
  subnet_id      = aws_subnet.RDJ-TF-PublicSub.id
  route_table_id = aws_route_table.RDJ-TF-PubRT.id
}

resource "aws_instance" "RDJ-TF" {
  ami           = "ami-0cff7528ff583bf9a"
  instance_type = "t2.micro"
  key_name = "rdjkey"
  subnet_id = aws_subnet.RDJ-TF-PublicSub.id
  vpc_security_group_ids = [aws_security_group.RDJ-TF-SecG.id]
  associate_public_ip_address = true

  tags = {
    Name = "RDJ-TF"
  }
  
  connection {
  type = "ssh"
  host = self.public_ip
  user = "ec2-user"
  private_key = "${file("rdjkey.pem")}"
  }

  # provisioner "file" {
  #   source      = "linux_command.sh"
  #   destination = "/tmp/linux_command.sh"
  # }

  provisioner "remote-exec" {
  inline = [
    # "sh /tmp/linux_command.sh"
    "sudo amazon-linux-extras install java-openjdk11 -y",
    "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
    "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
    "sudo yum install jenkins -y",
    "sudo systemctl start jenkins",
  ]
  }
}