# modules/k3s-cluster/iam.tf

# 1. ロール（役職）を作る
# "EC2インスタンス" がこの役職になれるようにする
resource "aws_iam_role" "k3s_role" {
  name = "${var.project_name}-${var.env}-k3s-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. ポリシー（許可証）を作る
# ASGを操作する権限を定義
resource "aws_iam_role_policy" "k3s_policy" {
  name = "${var.project_name}-${var.env}-k3s-autoscaling-policy"
  role = aws_iam_role.k3s_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
                  var.s3_bucket_arn,       # バケット自体への操作
                  "${var.s3_bucket_arn}/*" # 中身のオブジェクトへの操作
                ]
      }
    ]
  })
}

# 3. インスタンスプロファイル（名札）を作る
# これをEC2にくっつけることで、権限が発動する
resource "aws_iam_instance_profile" "k3s_profile" {
  name = "${var.project_name}-${var.env}-k3s-profile"
  role = aws_iam_role.k3s_role.name
}
