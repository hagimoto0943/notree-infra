resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "pdf_storage" {
  bucket = "${var.project_name}-${var.env}-pdf-storage-${random_string.suffix.result}"

  tags = {
    Name = "${var.project_name}-${var.env}-pdf-storage"
  }
}

# バケット名を外に公開（IAM設定で使うため）
output "bucket_name" {
  value = aws_s3_bucket.pdf_storage.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.pdf_storage.arn
}