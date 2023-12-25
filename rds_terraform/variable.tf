variable "vpc_cidr" {

    default = ["10.0.0.0/16"]
  
}

variable "sub_ip" {

    default = ["10.0.1.0/24", "10.0.2.0/24"]
  
}

 variable "cidr_gt" {

    default = ["0.0.0.0/0"]
   
 }

 variable "ami_id" {
   
   default = "ami-06aa3f7caf3a30282"

 }

 variable "type" {
   
   default = "t2.micro"

 }