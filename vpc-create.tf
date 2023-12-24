resource "aws_vpc" "myvpc" {

    cidr_block = var.vpccidr    
    
    
    tags = {
      "Name" = "myvpc"
    }
  
}

# public subnets
resource "aws_subnet" "subnets" {
    count             = length(var.subIP)
    vpc_id            = aws_vpc.myvpc.id
    cidr_block        = var.subIP[count.index]
    availability_zone = var.az[count.index]
    
    tags = {
      Name = "subnet-${count.index}"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rts" {
  count          = length(var.subIP)
  route_table_id = aws_route_table.rt.id
  subnet_id      = element(aws_subnet.subnets[*].id, count.index)
}


# private subnets
resource "aws_subnet" "subnets_pvt" {
    count             = length(var.sub_pvt)
    vpc_id            = aws_vpc.myvpc.id
    cidr_block        = var.sub_pvt[count.index]
    availability_zone = var.az[count.index]
    
    tags = {
      Name = "subnet-pvt-${count.index}"
    }
}
resource "aws_eip" "eip" {
  domain                    = "vpc"
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.subnets[*].id , 0) 
  tags = {
    Name = "gw-NAT"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "rt1" {
    vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }
}

resource "aws_route_table_association" "rts1" {
  count          = length(var.sub_pvt)
  route_table_id = aws_route_table.rt1.id
  subnet_id      = element(aws_subnet.subnets_pvt[*].id, count.index)
}


resource "aws_instance" "server-1" {

    ami = var.ami_id
    subnet_id = element(aws_subnet.subnets[*].id , 0)
    tags = {
      Name = "server-1"
    }
    instance_type = var.type
    associate_public_ip_address = "true"
    vpc_security_group_ids = [aws_security_group.allow_all_pub.id]
    key_name = "key_24_dec"

}



resource "aws_instance" "server-2" {

    ami = var.ami_id
    subnet_id = element(aws_subnet.subnets_pvt[*].id , 0)
    tags = {
      Name = "server-2"
    }
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.allow_all_pvt.id]
    key_name = "key_24_dec"

}


resource "aws_security_group" "allow_all_pub" {
  name        = "allow_all_pub"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description      = "traffic from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all_pub"
  }
}


resource "aws_security_group" "allow_all_pvt" {
  name        = "allow_all_pvt"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.myvpc.id
  ingress {
    description      = "traffic from public"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = [aws_security_group.allow_all_pub.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all_pvt"
  }
}