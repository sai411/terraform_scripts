resource "aws_vpc" "my-vpc" {

  cidr_block       =  var.vpc_cidr[0]

  tags = {
    Name = "vpc-1"
  }
}


resource "aws_subnet" "public-01" {
  
   vpc_id = aws_vpc.my-vpc.id
   availability_zone = "us-east-1a"
   cidr_block = element(var.sub_ip, 0)

}

resource "aws_subnet" "pvt-01" {
  
    vpc_id = aws_vpc.my-vpc.id
    availability_zone = "us-east-1b"
    cidr_block =  element(var.sub_ip, 1)

}

resource "aws_internet_gateway" "igwt-1" {
   
    vpc_id = aws_vpc.my-vpc.id
    
    tags = {
    Name = "igwt-01"
    }
  
}

resource "aws_eip" "eip" {

  domain = "vpc"
  tags =  {
    Name = "nat-01"
  }

}


resource "aws_nat_gateway" "nat-01" {

  subnet_id = aws_subnet.public-01.id
  connectivity_type = "public"
  allocation_id = aws_eip.eip.id

  }


resource "aws_route_table" "public-rt" {

  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = var.cidr_gt[0]
    gateway_id = aws_internet_gateway.igwt-1.id
  }
  tags = {
    Name = "pub-rt-myvpc"
  }
  
}

resource "aws_route_table" "pvt-tr" {
  
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = var.cidr_gt[0]
    nat_gateway_id = aws_nat_gateway.nat-01.id
  }

}

resource "aws_route_table_association" "pub-assiation" {

  route_table_id = aws_route_table.public-rt.id
  subnet_id = aws_subnet.public-01.id
  
}

resource "aws_route_table_association" "pvt-assiation" {
  
   route_table_id = aws_route_table.pvt-tr.id
   subnet_id = aws_subnet.pvt-01.id

}

resource "aws_instance" "server-1" {

    ami = var.ami_id
    subnet_id = aws_subnet.public-01.id
    tags = {
      Name = "server-1"
    }
    instance_type = var.type
    associate_public_ip_address = "true"
    vpc_security_group_ids = [aws_security_group.allow_tls_pub.id]
    key_name = "key_24_dec"

}



resource "aws_instance" "server-2" {

    ami = var.ami_id
    subnet_id = aws_subnet.pvt-01.id
    tags = {
      Name = "server-2"
    }
    instance_type = var.type
    vpc_security_group_ids = [aws_security_group.allow_tls_pvt.id]
    key_name = "key_24_dec"

}


resource "aws_security_group" "allow_tls_pub" {
  name        = "allow_tls_pub"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    description      = "TLS from VPC"
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
    Name = "allow_tls_pub"
  }
}


resource "aws_security_group" "allow_tls_pvt" {
  name        = "allow_tls_pvt"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = [aws_security_group.allow_tls_pub.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls_pvt"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "s-db"
  subnet_ids = [aws_subnet.public-01.id, aws_subnet.pvt-01.id]

  tags = {
    Name = "s-db"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for RDS instance"
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    security_groups = [aws_security_group.allow_tls_pvt.id]
  }
}


resource "aws_db_instance" "sql-db" {
  allocated_storage           = 10
  db_name                     = "mydb"
  identifier                  = "ee-instance-demo"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t3.micro"
  username                    = "admin123"
  password                    = "admin123"
  parameter_group_name        = "default.mysql5.7"
  availability_zone = "us-east-1a"
  iam_database_authentication_enabled = true
  skip_final_snapshot = true
  

  db_subnet_group_name        =  aws_db_subnet_group.default.name
  
  vpc_security_group_ids      = [aws_security_group.db_sg.id]

}

resource "aws_sns_topic" "send-mail" {

     name = "send-mail"
     

   }


resource "aws_sns_topic_subscription" "mail-sub" {
  topic_arn = aws_sns_topic.send-mail.arn
  protocol  = "email"
  endpoint  = "your@gmail.com"
}

output "db_instance_identifier" {
  value = aws_db_instance.sql-db.identifier
}


resource "aws_cloudwatch_metric_alarm" "db_cpu_alarm" {
  alarm_name                = "tf-db-cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"  
  dimensions = {
    DBInstanceIdentifier =  aws_db_instance.sql-db.identifier
  }
  period                    = 60
  statistic                 = "Average"
  threshold                 = 0.1
  alarm_description         = "This metric monitors RDS instance cpu utilization"
  alarm_actions             = [aws_sns_topic.send-mail.arn]
  ok_actions = [aws_sns_topic.send-mail.arn]
}