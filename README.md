# Terraform_EC2-Instance-With-Keypair-and-User-Data

### Project

Terraform to automate the launch of an EC2 instance on AWS. The project includes the generation of a downloadable key pair for the instance and the execution of the user data script to install and Configure Apache HTTP server.

---

## Objectives

1.Terraform Configuration.

- We will learn to write Terraform code to launch an EC2 instance with specified configurations.

2.Key Pair Generation.

- Generate a key pair and make it downloadable after EC2 instance creation.

2.User Data Execution

- Use terraform to execute a user data script on the EC2 instance during launch.

### Project Task:

---

#### **Task 1: EC2 Instance Configuration**
#### 1️⃣ **Creating the Terraform Project Directory**

```sh
mkdir terraform-EC2-keypair
```
This command creates a new directory (`terraform-EC2-keypair`) where the Terraform files will be stored.

 ![](./img/f1.png)

#### 2️⃣ **Creating the Terraform Configuration File**
```sh
touch main.tf
```
This creates an empty Terraform file named `main.tf`, where the configuration will be written.

![](./img/f2.png)

#### 3️⃣ **Defining the AWS Provider**
```hcl
provider "aws" {
  region = "us-east-1"
}
```
- Specifies **AWS** as the cloud provider.
- Defines **the AWS region** (`us-east-1`) where the resources will be deployed.

---

#### **Task 2: Generating and Storing an SSH Key Pair**
#### **Key Pair Generation**
```hcl
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
```
- **Generates a new RSA private key** with a **2048-bit encryption strength**.
- The private key is stored in Terraform’s memory.
- **Why RSA?** It's a widely used, secure cryptographic algorithm for SSH authentication.

#### **Uploading the Public Key to AWS**
```hcl
resource "aws_key_pair" "new_key_pair" {
  key_name   = "auto-generated-key-pair"
  public_key = tls_private_key.generated.public_key_openssh
}
```
- Terraform extracts the **public portion** of the RSA key and **uploads** it to AWS.
- The instance uses this key for **SSH authentication**.

#### **Making the Private Key Downloadable**
```hcl
output "private_key" {
  value     = tls_private_key.generated.private_key_pem
  sensitive = true
}
```
- The private key is **output** when `terraform apply` is executed.
- It is **marked as `sensitive`**, meaning Terraform won’t display it in logs.

#### **Downloading the Key**
After running `terraform apply`, you need to **save the key** manually:
```sh
terraform output -raw private_key > my-key.pem
```
This saves the private key as `my-key.pem`.

#### **Setting Proper Permissions**
Before using the key, **restrict its permissions**:
```sh
chmod 400 my-key.pem
```
This prevents others from accessing it.

---

#### **Task 3: Security Group Configuration**
#### **Allowing HTTP Traffic (Port 80)**
```hcl
resource "aws_security_group" "allow_http" {
  name_prefix = "allow-http-"

  ingress {
    from_port   = 80
    to_port     = 80
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
```
- **Ingress Rule** allows all incoming HTTP traffic (`port 80`) from anywhere (`0.0.0.0/0`).
- **Egress Rule** allows all outbound traffic.

---

#### **Task 4: Deploying the EC2 Instance**
```hcl
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.new_key_pair.key_name

  security_groups = [
    aws_security_group.allow_http.name
  ]

  tags = {
    Name = "MyInstance"
  }
}
```
- Launches an **EC2 instance** using the latest Ubuntu AMI.
- Assigns the **generated key pair** for SSH access.
- Attaches the **security group** allowing HTTP traffic.

---

#### **Task 5: Executing a User Data Script**
```hcl
user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y apache2
  sudo systemctl enable apache2
  sudo systemctl start apache2
  echo "<html><h1>Hello World!</h1></html>" > /var/www/html/index.html
EOF
```
- **Installs Apache** (`apache2`).
- **Enables auto-start** so Apache runs on system boot.
- **Creates a simple webpage (`index.html`)** displaying `"Hello World!"`.

---

#### **Task 6: Retrieving the Public IP**
#### **Adding an Output**
```hcl
output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
```
- Terraform **outputs the EC2 instance’s public IP** after deployment.

#### **Accessing the Web Server**
- Open a browser and enter:
  ```
  http://<PUBLIC_IP>
  ```
- You should see `"Hello World!"` displayed.

---

### The Complete `main.tf` configuration file.

**full Terraform script**, combining **EC2 instance creation**, **key pair generation**, **security group configuration**, and **user data execution** into a single `main.tf` file.

```hcl
provider "aws" {
  region = "us-east-1"
}

# Fetch the latest Ubuntu AMI
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

  owners = ["099720109477"]  # Canonical's AWS account ID
}

# Generate a key pair
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "new_key_pair" {
  key_name   = "auto-generated-key-pair"
  public_key = tls_private_key.generated.public_key_openssh
}

# Security group allowing HTTP traffic
resource "aws_security_group" "allow_http" {
  name_prefix = "allow-http-"

  ingress {
    from_port   = 80
    to_port     = 80
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

# EC2 instance configuration with user data script
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.new_key_pair.key_name

  security_groups = [aws_security_group.allow_http.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              sudo systemctl enable apache2
              sudo systemctl start apache2
              echo "<html><h1>Hello World!</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "MyInstance"
  }
}

# Output the private key
output "private_key" {
  value     = tls_private_key.generated.private_key_pem
  sensitive = true
}

# Output the key name
output "key_name" {
  value = aws_key_pair.new_key_pair.key_name
}

# Output the public IP for accessing the web server
output "public_ip" {
  value = aws_instance.my_instance.public_ip
}
```

#### **How to Use This Script**
1. **Initialize Terraform**:
   ```sh
   terraform init
   ```

    ![](./img/f3.png)
  
  
  - **terraform fmt**: Automatically formats Terraform configuration files to follow proper coding conventions.  
  - **terraform validate**: Checks the configuration for syntax errors and logical issues before applying changes.  
  - **terraform plan**: Shows a preview of the changes Terraform will make before applying them.
  


2. **Deploy the resources**:
   ```sh
   terraform apply -auto-approve
   ```

3. **Save the private key**:
   ```sh
   terraform output -raw private_key > my-key.pem
   chmod 400 my-key.pem
   ```

4. **Access the EC2 instance**:
   ```sh
   ssh -i my-key.pem ubuntu@<PUBLIC_IP>
   ```

5. **Check the web server**:
   - Open a browser and enter:
     ```
     http://<PUBLIC_IP>
     ```
   - You should see `"Hello World!"` displayed.

      ![](./img/f4.png)

This script ensures **end-to-end automation**, from **key pair generation**, **instance launch**, to **Apache installation** with a **basic web page**.


### **Possible Enhancements**
##### 1️⃣ **Improved Security**
Instead of allowing **all incoming traffic (`0.0.0.0/0`)**, you could **restrict access** to specific IP ranges:
```hcl
cidr_blocks = ["YOUR_IP/32"]
```
This ensures that only **your** IP can access the instance.

##### 2️⃣ **Automated Private Key Storage**
Instead of manually saving the private key, store it securely in **AWS Secrets Manager**:
```hcl
resource "aws_secretsmanager_secret" "ssh_key" {
  name = "EC2-private-key"
}

resource "aws_secretsmanager_secret_version" "ssh_key_version" {
  secret_id     = aws_secretsmanager_secret.ssh_key.id
  secret_string = tls_private_key.generated.private_key_pem
}
```

##### 3️⃣ **Automated Apache Configuration**
Instead of storing HTML content in `index.html`, configure Apache **using Ansible**:
- Terraform provisions the EC2 instance.
- Ansible automates web server setup.
- Apache serves a **custom website** instead of just `"Hello World!"`.



