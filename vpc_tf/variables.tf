//variable "key" {}  

variable "az" {

    default = ["us-east-1a", "us-east-1b"]  
}

variable "vpccidr" {

    default = "192.0.0.0/16"
  
}

variable "subIP" {
  
  default = ["192.0.1.0/24", "192.0.2.0/24"]

}

variable "sub_pvt" {

  default = ["192.0.3.0/24", "192.0.4.0/24" ]
  
}

variable "ami_id" {

  default = "ami-079db87dc4c10ac91"
  
}

variable "type" {

   default = "t2.micro"

}
