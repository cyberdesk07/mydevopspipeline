provider "aws" {
  region     = "ap-south-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Create a security group for Jenkins
resource "aws_security_group" "jenkins" {
  name   = "jenkins-security-group"
  vpc_id = "vpc-027a3aa4e34d2e51d"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9000
    to_port     = 9000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

# Create an EC2 instance with Jenkins
resource "aws_instance" "jenkins" {
  ami                    = "ami-0c2af51e265bd5e0e" 
  instance_type          = "t2.large"
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = "subnet-089232bc15db88c53"
  key_name               = "priyanshudevops"

  root_block_device {
    volume_size = 30
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("D:/priyanshudevops.pem")
      timeout     = "5m"
    }

    inline = [
      "sudo apt update",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",
      "sudo apt-get install -y wget apt-transport-https gnupg lsb-release",
      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null",
      "echo \"deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main\" | sudo tee -a /etc/apt/sources.list.d/trivy.list",
      "sudo apt-get update",
      "sudo apt-get install -y trivy",
      "sudo apt install -y fontconfig openjdk-17-jre",
      "java -version",
      "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
      "echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",
      # Install Jenkins plugins for SonarQube integration
      "sudo wget -q -O /tmp/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar",
      "sudo java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/ install-plugin sonar workflow-aggregator git",
      "sudo systemctl restart jenkins",
      # Wait for Jenkins to be fully up and running
      "while ! nc -z localhost 8080; do sleep 10; done"
    ]
  }

  tags = {
    Name = "jenkins-instance"
  }
}