# vpc cidr block
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
# public subnet-1 cidr block
variable "public_subnet1_cidr" {
  default = "10.0.1.0/24"
}
# availability zone public subnet 1
variable "az1" {
  default = "eu-west-3a"
}
# availability zone public subnet 1
variable "az2" {
  default = "eu-west-3b"
}
# private subnet-1 cidr block
variable "private_subnet1_cidr" {
  default = "10.0.2.0/24"
}
# private subnet-1 cidr block
variable "private_subnet2_cidr" {
  default = "10.0.3.0/24"
}
# webserver ami
variable "ami_webserver" {
  default = "ami-0f4447ed9b385bedf"
}
# webserver ami
variable "ami_webserver2" {
  default = "ami-05b457b541faec0ca"
}
# webserver instance type
variable "instance_type" {
  default = "t2.micro"
}
# webserver instance type2
variable "instance_type2" {
  default = "t3.medium"
}
# database name
variable "db_name" {
  default = "onlinebookstore"
}
# database username
variable "db_username" {
  default = "onlinebook"
}
# database password
variable "db_password" {
  default = "onlinebook"
}