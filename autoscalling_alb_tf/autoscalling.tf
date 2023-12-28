resource "aws_launch_template" "my-lt" {
  name  = "lt-01"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name = "key_24_dec"
  vpc_security_group_ids = [aws_security_group.allow_all_pub.id]


  }

resource "aws_autoscaling_group" "example" {
  name = "autoscale-01"
  capacity_rebalance  = true
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [element(aws_subnet.subnets[*].id, 0), element(aws_subnet.subnets[*].id, 1)]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.my-lt.id
      }

    }
  }
  
}

output "tg" {
  value = regex("targetgroup.*", aws_lb_target_group.test.arn)
}

output "app" {

    value = regex("app.*", aws_lb.lb-01.arn)
  
}

resource "aws_autoscaling_policy" "example_1" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  name                   = "foo"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 10
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = join("", [regex("app.*", aws_lb.lb-01.arn), "/", regex("targetgroup.*", aws_lb_target_group.test.arn)])
    }
  }
}
