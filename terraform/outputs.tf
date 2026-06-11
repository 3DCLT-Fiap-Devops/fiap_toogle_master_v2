output "vpc_id" {
  value = aws_vpc.main.id
}

output "rds_auth_endpoint" {
  value = aws_db_instance.auth_db.endpoint
}

output "rds_main_endpoint" {
  value = aws_db_instance.main_db.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "sqs_url" {
  value = aws_sqs_queue.events.url
}

output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "db_password" {
  value     = var.db_password
  sensitive = true
}

output "region" {
  value = var.region
}
