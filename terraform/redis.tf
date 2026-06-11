resource "aws_elasticache_cluster" "main" {
  cluster_id           = "toogle-redis"
  engine               = "redis"
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.main.id]

  tags = {
    Project = var.project_name
  }
}
