# ---------------------------------------------------------
# SSH Key Pair
# ---------------------------------------------------------

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name = "${var.project_name}-${var.environment}-ssh-key"
  }
}

# Save private key locally
resource "local_sensitive_file" "ssh_private_key" {
  filename        = "${path.module}/ssh_key.pem"
  content         = tls_private_key.ssh_key.private_key_pem
  file_permission = "0600"
}

# ---------------------------------------------------------
# EC2 Application Server
# ---------------------------------------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  associate_public_ip_address = true

  # Attach SSH key pair
  key_name = aws_key_pair.ssh_key.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash

              set -eux

              exec > >(tee /var/log/8byte-bootstrap.log | logger -t 8byte-bootstrap -s 2>/dev/console) 2>&1

              echo "Starting 8Byte EC2 bootstrap"

              apt-get update -y

              apt-get install -y \
                ca-certificates \
                curl \
                gnupg

              install -m 0755 -d /etc/apt/keyrings

              curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                -o /etc/apt/keyrings/docker.asc

              chmod a+r /etc/apt/keyrings/docker.asc

              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                > /etc/apt/sources.list.d/docker.list

              apt-get update -y

              apt-get install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin

              systemctl enable docker
              systemctl start docker

              usermod -aG docker ubuntu

              echo "Docker installation completed" >> /var/log/8byte-bootstrap.log

              docker --version >> /var/log/8byte-bootstrap.log

              echo "8Byte bootstrap completed" >> /var/log/8byte-bootstrap.log
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-server"
    Role = "application"
  }
}