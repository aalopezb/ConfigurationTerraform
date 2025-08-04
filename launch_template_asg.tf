resource "aws_launch_template" "lt" {
  count        = var.instance_count
  name_prefix  = "app-lt-${count.index + 1}-"
  image_id     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2, ajustar según región
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg[count.index].id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  count               = var.instance_count
  name                = "app-asg-${count.index + 1}"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  launch_template {
    id      = aws_launch_template.lt[count.index].id
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.public.ids
  target_group_arns   = [aws_lb_target_group.tg[count.index].arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "app-instance-${count.index + 1}"
    propagate_at_launch = true
  }
}
