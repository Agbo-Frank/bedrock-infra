
resource "aws_db_subnet_group" "main" {
  name       = "${var.title}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.title}-db-subnet-group"
  }
}


resource "aws_security_group" "mysql" {
  name        = "${var.title}-mysql-sg"
  description = "Allow MySQL traffic from within the VPC"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.title}-mysql-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id = aws_security_group.mysql.id
  description       = "MySQL from VPC"
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_vpc_security_group_egress_rule" "mysql" {
  security_group_id = aws_security_group.mysql.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "postgres" {
  name        = "${var.title}-postgres-sg"
  description = "Allow PostgreSQL traffic from within the VPC"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.title}-postgres-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id = aws_security_group.postgres.id
  description       = "PostgreSQL from VPC"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/16"
}

resource "aws_vpc_security_group_egress_rule" "postgres" {
  security_group_id = aws_security_group.postgres.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


resource "random_password" "mysql" {
  length  = 16
  special = false
}

resource "random_password" "postgres" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "mysql" {
  name                    = "${var.title}/rds/mysql"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.title}-mysql-secret"
  }
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.mysql.result
    dbname   = var.mysql_db_name
    host     = aws_db_instance.mysql.address
    port     = 3306
  })
}

resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.title}/rds/postgres"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.title}-postgres-secret"
  }
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.postgres.result
    dbname   = var.postgres_db_name
    host     = aws_db_instance.postgres.address
    port     = 5432
  })
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.title}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.mysql_db_name
  username               = var.db_username
  password               = random_password.mysql.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.mysql.id]
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "${var.title}-mysql"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.title}-postgres"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = var.postgres_db_name
  username               = var.db_username
  password               = random_password.postgres.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "${var.title}-postgres"
  }
}
