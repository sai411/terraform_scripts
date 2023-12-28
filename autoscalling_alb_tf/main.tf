resource "aws_lb" "lb-01" {

  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets = [element(aws_subnet.subnets[*].id, 0), element(aws_subnet.subnets[*].id, 1)]

}

resource "aws_lb_listener" "name" {
  

   load_balancer_arn = aws_lb.lb-01.arn
   port = 80
   default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}


resource "aws_lb_target_group" "test" {

  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id

}



# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  lb_target_group_arn    = aws_lb_target_group.test.arn
}
