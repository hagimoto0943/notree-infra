resource "aws_security_group" "k3s" {
  name        = "k3s-sg-${var.project_name}-${var.env}"
  description = "Allow SSH, K8s API, HTTP"
  vpc_id      = var.vpc_id

  # SSH (22) for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s API (6443) for kubectl
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS (80/443) for application
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inner Connection
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1" # myself
    self      = true
  }

  # Outbound apply all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-sg-${var.project_name}-${var.env}"
  }
}


# Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.k3s.id]

  key_name = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  iam_instance_profile = aws_iam_instance_profile.k3s_profile.name

  tags = {
    Name = "k3s-master-${var.project_name}-${var.env}"
  }
}

resource "aws_launch_template" "worker" {
  name_prefix   = "${var.project_name}-${var.env}-worker-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "c5.large"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.k3s.id]
  }

  key_name = var.key_name

  # ★最重要：起動した瞬間に実行されるスクリプト (User Data)
  # ここで自動的にK3sをインストールし、Masterに参加させる
  user_data = base64encode(<<-EOF
                #!/bin/bash

                # 1. まずトークンを取得する (これが無いと最近のAWSでは拒否される)
                TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

                # 2. トークンを使ってメタデータを取得
                AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
                ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

                # 3. ProviderIDを組み立てる
                PROVIDER_ID="aws:///$AZ/$ID"

                # 4. K3sインストール
                curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.master.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - --kubelet-arg="provider-id=$PROVIDER_ID"
                EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k3s-worker-spot-${var.project_name}-${var.env}"
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k3s_profile.name
  }
}

resource "aws_autoscaling_group" "worker" {
  name                = "worker-asg-${var.project_name}-${var.env}"
  desired_capacity    = 1
  max_size            = 5
  min_size            = 0
  vpc_zone_identifier = [var.subnet_id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0                    # 定価のサーバーは0台
      on_demand_percentage_above_base_capacity = 0                    # 追加分も全部スポット(100%)
      spot_allocation_strategy                 = "capacity-optimized" # 在庫が豊富なやつを選ぶ
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker.id
        version            = "$Latest"
      }
      # 在庫切れ対策：もしc5.largeがなければ、これらを使う
      override { instance_type = "c5.large" }
      override { instance_type = "m5.large" }
      override { instance_type = "t3.large" }
    }
  }
  tag {
    key                 = "Role"
    value               = "worker"
    propagate_at_launch = true
  }
}
