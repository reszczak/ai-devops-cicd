output "bucket_name" {
  description = "Nazwa bucketu na artefakty buildów"
  value       = aws_s3_bucket.artefakty.id
}

output "vpc_id" {
  description = "ID utworzonej VPC"
  value       = aws_vpc.glowna.id
}

output "security_group_id" {
  description = "ID security group aplikacji"
  value       = aws_security_group.aplikacja.id
}
