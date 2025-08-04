provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "principal" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publica" {
  vpc_id                  = aws_vpc.principal.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.principal.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  count       = 5
  name        = "sg-${count.index}"
  description = "Security group para EC2 ${count.index}"
  vpc_id      = aws_vpc.principal.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "mi_clave" {
  key_name   = "mi_clave_aws"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_launch_template" "plantilla" {
  name_prefix   = "plantilla-ec2"
  image_id      = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mi_clave.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg[0].id]
  }
}

resource "aws_lb" "lb" {
  name               = "mi-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg[0].id]
  subnets            = [aws_subnet.publica.id]
}

resource "aws_lb_target_group" "grupo_objetivo" {
  name     = "tg-ec2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.principal.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grupo_objetivo.arn
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 5
  max_size             = 5
  min_size             = 5
  vpc_zone_identifier  = [aws_subnet.publica.id]

  launch_template {
    id      = aws_launch_template.plantilla.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.grupo_objetivo.arn]
  depends_on        = [aws_lb.lb]
}
