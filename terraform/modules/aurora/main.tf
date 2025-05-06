resource "aws_db_subnet_group" "aurora" {
  name       = "${replace(lower(var.db_name), "_", "-")}-subnet-group"
  subnet_ids = var.subnets
}

resource "aws_security_group" "aurora" {
  name        = "${replace(lower(var.db_name), "_", "-")}-aurora-sg"
  description = "Allow Postgres access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${replace(lower(var.db_name), "_", "-")}-aurora-cluster"
  engine                  = "aurora-postgresql"
  database_name           = var.db_name
  master_username         = var.db_user
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora.id]
  skip_final_snapshot     = true

    serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0

  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier              = "${replace(lower(var.db_name), "_", "-")}-writer"
  cluster_identifier      = aws_rds_cluster.aurora.id
  instance_class          = "db.serverless"
  engine                  = aws_rds_cluster.aurora.engine
  engine_version          = aws_rds_cluster.aurora.engine_version
  publicly_accessible     = false
}
