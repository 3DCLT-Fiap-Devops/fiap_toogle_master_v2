resource "aws_db_instance" "auth_db" {
  identifier           = "auth-db"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  engine               = "postgres"
  username             = "dbuser"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
  publicly_accessible  = true
  skip_final_snapshot  = true

  tags = {
    Project = var.project_name
    Service = "Auth"
  }
}

resource "aws_db_instance" "main_db" {
  identifier           = "main-db"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  engine               = "postgres"
  username             = "dbuser"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]
  publicly_accessible  = true
  skip_final_snapshot  = true

  tags = {
    Project = var.project_name
    Service = "Core"
  }
}
