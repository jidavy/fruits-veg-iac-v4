packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "nginx" {
  region        = "eu-west-2"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"
  ami_name      = "nginx-git-by-packer"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023*-x86_64"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

source "amazon-ebs" "backend" {
  region        = "eu-west-2"
  instance_type = "t3.micro"
  ssh_username  = "ec2-user"
  ami_name      = "python-java-git-by-packer"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023*-x86_64"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

build {
  name    = "nginx-ami"
  sources = ["source.amazon-ebs.nginx"]

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y nginx git",
      "git clone https://github.com/jidavy/fruits-veg_market.git /tmp/fruits-veg_market",
      "sudo cp -r /tmp/fruits-veg_market/web/* /usr/share/nginx/html/",
      "sudo sed -i 's/FRUIT_MACHINE:9000/PYTHON_NODE_IP:8080/' /usr/share/nginx/html/index.html",
      "sudo sed -i 's/VEG_MACHINE:8080/JAVA_NODE_IP:9090/' /usr/share/nginx/html/index.html",
      "sudo systemctl enable nginx"
    ]
  }
}

build {
  name    = "backend-ami"
  sources = ["source.amazon-ebs.backend"]

  provisioner "file" {
    source      = "fruits.service"
    destination = "/tmp/fruits.service"
  }

  provisioner "file" {
    source      = "produce.service"
    destination = "/tmp/produce.service"
  }

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y git python3 java-17-amazon-corretto-devel maven",
      "git clone https://github.com/jidavy/fruits-veg_market.git /home/ec2-user/fruits-veg_market",
      "cd /home/ec2-user/fruits-veg_market/python && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt",
      "cd /home/ec2-user/fruits-veg_market/java && mvn clean package -DskipTests",
      "sudo cp /tmp/fruits.service /etc/systemd/system/fruits.service",
      "sudo cp /tmp/produce.service /etc/systemd/system/produce.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable fruits produce"
    ]
  }
}
