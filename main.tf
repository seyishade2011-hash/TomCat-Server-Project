provider "aws" {
  region  = "eu-west-3"
  profile = "default"
}
locals {
  name = "train-project"
}
# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "${local.name}-vpc"
  }
}
#creating the RSA keypair of size 4096 bits
resource "tls_private_key" "eu2acp" { 
  algorithm = "RSA"
  rsa_bits  = 4096
}
//saving the private key locally
resource "local_file" "eu2acp" {
  content         = tls_private_key.eu2acp.private_key_pem
  filename        = "eu2acp-key"
  file_permission = "600"
}
//Registering the Public Key on AWS
resource "aws_key_pair" "eu2acp" {
  key_name   = "eu2acp-pub-key"
  public_key = tls_private_key.eu2acp.public_key_openssh
}
# Creating public subnet 1
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet1_cidr
  availability_zone = var.az1
  tags = {
    Name = "${local.name}-Public subnet1"
  }
}
# Creating private subnet 1
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = var.az1
  tags = {
    Name = "${local.name}-Private subnet1"
  }
}
# Creating private subnet 2
resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = var.az2
  tags = {
    Name = "${local.name}-Private subnet2"
  }
}
# Creating internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.name}-igw"
  }
}
# Create elastic ip
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${local.name}-eip"
  }
}
#create a nat gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public-subnet-1.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.name}-ngw"
  }
}
# Create Route Table
# Public Route Table
resource "aws_route_table" "eu-2-publicRT" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
# Private Route Table
resource "aws_route_table" "eu-2-privateRT" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
}
# Create Public Subnet Route Table Association PUB01
resource "aws_route_table_association" "public_subnet_rt-ASC01" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.eu-2-publicRT.id
}
# Create Private Subnet Route Table Association PRIV01
resource "aws_route_table_association" "private_subnet_rt-ASC01" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.eu-2-privateRT.id
}
# Create Private Subnet Route Table Association PRIV02
resource "aws_route_table_association" "private_subnet_rt-ASC02" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.eu-2-privateRT.id
}
# Create Security_Groups FrontEnd
resource "aws_security_group" "sg-frontend" {
  name        = "frontend"
  description = "frontend_security_group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "rds access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "${local.name}-sg-frontend"
  }
}
# Create Security_Groups Jenkins
resource "aws_security_group" "sg-jenkins" {
  name        = "jenkins"
  description = "jenkins"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Jenkins access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "tomcat access"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "${local.name}-sg-jenkins"
  }
}
# Create Security_Groups bastion
resource "aws_security_group" "sg-bastion" {
  name        = "bastion"
  description = "bastion"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "bastion access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "${local.name}-sg-bastion"
  }
}
# Create Security_Groups BackEnd
resource "aws_security_group" "sg-backend" {
  name        = "backend"
  description = "backend_security_group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "mysql access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-jenkins.id, aws_security_group.sg-bastion.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "${local.name}-sg-backend"
  }
}
resource "aws_instance" "jenkins" {
  ami                         = var.ami_webserver
  instance_type               = var.instance_type2
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet-1.id
  key_name                    = aws_key_pair.eu2acp.id
  vpc_security_group_ids      = [aws_security_group.sg-jenkins.id]
  user_data                   = file("./jenkins_userdata.sh")
  tags = {
    Name = "${local.name}-jenkins"
  }
}
resource "aws_instance" "bastion" {
  ami                         = var.ami_webserver
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet-1.id
  key_name                    = aws_key_pair.eu2acp.id
  vpc_security_group_ids      = [aws_security_group.sg-bastion.id]
  user_data                   = file("./bastion_userdata.sh")
  tags = {
    Name = "${local.name}-bastion"
  }
}
resource "aws_instance" "tomcat" {
  ami                         = var.ami_webserver2
  instance_type               = var.instance_type2
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet-1.id
  key_name                    = aws_key_pair.eu2acp.id
  vpc_security_group_ids      = [aws_security_group.sg-jenkins.id]
  user_data                   = file("./tomcat_userdata.sh")
  tags = {
    Name = "${local.name}-tomcat"
  }
}
#creating database subnet group
resource "aws_db_subnet_group" "team2_capstone_db_subnet_group" {
  name       = "team2_capstone_db_subnet_group"
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
  tags = {
    Name = "${local.name}-DB subnet group"
  }
}
# Creating Mysql wordpress database 
resource "aws_db_instance" "onlinebookstore" {
  identifier             = "onlinebookstore"
  db_subnet_group_name   = aws_db_subnet_group.team2_capstone_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.sg-backend.id]
  allocated_storage      = 10
  # backup_retention_period = 7
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  parameter_group_name = "default.mysql5.7"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  publicly_accessible  = false
}