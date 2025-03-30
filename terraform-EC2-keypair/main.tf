provider "aws" {
  region = "us-east-1" # Change this to your preferred AWS region
}

# Security Group
resource "aws_security_group" "next_sg" {
  name        = "next_sg"
  description = "Allow HTTP, HTTPS, and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH (modify to restrict access for security)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "NextServer-SG"
  }
}

# EC2 Instance with Updated Type and User Data
resource "aws_instance" "example_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # Updated to a larger instance type
  key_name      = "Edward1"  # Replace with your key pair name
  security_groups = [
    aws_security_group.next_sg.name,
  ]

  # User Data Script
  user_data = <<-EOF
              #!/bin/bash
              # Update package manager
              sudo apt-get update
              
              # Install Apache HTTP Server
              sudo apt-get install -y apache2
              
              # Enable Apache to start on boot
              sudo systemctl enable apache2
              
              # Start Apache Service
              sudo systemctl start apache2
              
              # Create HTML Page to Serve
              echo "<html><h1>Hello World!</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "UpdatedExampleInstance"
  }
}

# Data Source for the Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

output "public_ip" {
  value = aws_instance.example_instance.public_ip
}