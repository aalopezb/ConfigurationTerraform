output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
  description = "DNS del Application Load Balancer"
}

output "instance_security_groups" {
  value = [for sg in aws_security_group.instance_sg : sg.id]
  description = "IDs de Security Groups de instancias"
}

output "autoscaling_group_names" {
  value = [for asg in aws_autoscaling_group.asg : asg.name]
  description = "Nombres de los Auto Scaling Groups"
}
