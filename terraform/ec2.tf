# ---------------------------------------------------------
# EC2 Application Server
# ---------------------------------------------------------

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # No NAT Gateway required.
  # EC2 is placed in the public subnet so it can bootstrap
  # itself using the Internet Gateway.
  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash

              set -eux

              exec > >(tee /var/log/8byte-bootstrap.log | logger -t 8byte-bootstrap -s 2>/dev/console) 2>&1

              echo "Starting 8Byte application bootstrap..."

              # -------------------------------------------------
              # Install required packages
              # -------------------------------------------------

              apt-get update -y

              apt-get install -y \
                ca-certificates \
                curl \
                git \
                gnupg

              # -------------------------------------------------
              # Install Docker
              # -------------------------------------------------

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

              # -------------------------------------------------
              # Clone application repository
              # -------------------------------------------------

              cd /opt

              rm -rf 8byte-devops-assignment

              git clone https://github.com/Onkar11092000/8byte-devops-assignment.git 8byte-devops-assignment

              cd /opt/8byte-devops-assignment/app

              # -------------------------------------------------
              # Build application Docker image
              # -------------------------------------------------

              docker build -t 8byte-devops-demo:latest .

              # -------------------------------------------------
              # Run application
              # -------------------------------------------------

              docker rm -f 8byte-devops-app 2>/dev/null || true

              docker run -d \
                --name 8byte-devops-app \
                --restart unless-stopped \
                -p 3000:3000 \
                8byte-devops-demo:latest

              echo "8Byte application deployment completed."

              docker ps

              echo "Bootstrap completed successfully." >> /var/log/8byte-bootstrap.log
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-server"
    Role = "application"
  }
}