# ================================================= Target Group =================================================
resource "aws_lb_target_group" "targetGroup" {
  name             = "${var.RESOURCE_PREFIX}TG"
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "ip"
  vpc_id           = var.VPC_ID

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 20
    matcher             = 200
    path                = "/"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 2
  }
}


# ================================================= Load Balancer =================================================
resource "aws_lb" "load_balancer" {
  name                             = "${var.RESOURCE_PREFIX}LB"
  load_balancer_type               = "application"
  internal                         = false
  security_groups                  = [var.DEFAULT_SECURITY_GROUP_ID]
  ip_address_type                  = "ipv4"
  subnets                          = var.PUBLIC_SUBNETS
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = false

  tags = {
    Name = "${var.RESOURCE_PREFIX}LB"
  }
}


# ================================================= Load Balancer Listener =================================================
resource "aws_lb_listener" "load_balancer__listener" {
  count = length(var.PORTS)
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = var.PORTS[count.index]
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.targetGroup.id
  }

  depends_on = [
    aws_lb.load_balancer,
    aws_lb_target_group.targetGroup
  ]
}