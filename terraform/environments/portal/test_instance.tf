locals {

  httpd_userdata = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd
echo "Hello World" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF

}

######################################
# Test HTTPD Instance
######################################

resource "aws_instance" "httpd_instance" {
  ami                         = "ami-0f3d9639a5674d559" #Amazon Linux AMI
  availability_zone           = "eu-west-2a"
  instance_type               = t2.medium
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.httpd.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.portal.id
  user_data_base64            = base64encode(local.httpd_userdata)
  user_data_replace_on_change = true

  tags = merge(
    {"instance-scheduling" = "skip-scheduling"},
    local.tags,
    { "Name" = "${local.application_name} HTTPD Instance" }
  )
}


############################################
# HTTPD EC2 Security Group
############################################

resource "aws_security_group" "httpd" {
  name        = "httpd-sg"
  description = "HTTPD Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "httpd_outbound" {
  security_group_id = aws_security_group.httpd.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_rdp_workspace" {
  security_group_id = aws_security_group.httpd.id
  description       = "SSH Inbound from WorkSpaces"
  cidr_ipv4         = local.nonprod_workspaces_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


############################################
# HTTPD ELB Security Group
############################################

resource "aws_security_group" "httpd_lb" {
  name        = "httpd-lb-security-group"
  description = "httpd alb security group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "httpd_lb_vpc" {
  security_group_id = aws_security_group.httpd_lb.id
  description       = "From account VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "httpd_lb_vpc_https" {
  security_group_id = aws_security_group.httpd_lb.id
  description       = "From account VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block #!ImportValue env-VpcCidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "httpd_lb_https_np_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.httpd_lb.id
  description       = "HTTPS access for non-prod London Workspaces"
  cidr_ipv4         = local.nonprod_workspaces_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "httpd_lb_http_np_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 1 : 0
  security_group_id = aws_security_group.httpd_lb.id
  description       = "HTTP access for non-prod London Workspaces"
  cidr_ipv4         = local.nonprod_workspaces_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_ingress_rule" "httpd_lb_https_prd_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  security_group_id = aws_security_group.httpd_lb.id
  description       = "HTPS access for prod London Workspaces"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "httpdlb_http_prd_workspaces" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  security_group_id = aws_security_group.httpd_lb.id
  description       = "HTTP access for prod London Workspaces"
  cidr_ipv4         = local.prod_workspaces_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "httpd_lb_outbound" {
  security_group_id = aws_security_group.httpd_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

####################################
# HTTPD ELB to HTTPD EC2
####################################

resource "aws_lb" "httpd" {
  name               = "httpd-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.httpd_lb.id]
  subnets            = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  # enable_deletion_protection = local.enable_deletion_protection
  idle_timeout = 180

#   access_logs {
#     bucket  = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
#     prefix  = "${local.application_name}-internal-lb"
#     enabled = true
#   }

  tags = merge(
    local.tags,
    {
      Name = "httpd-lb"
    },
  )
}

resource "aws_lb_target_group" "httpd" {
  name                 = "htpd-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30
  # load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    interval            = 5
    path                = "/"
    protocol            = "HTTP"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 302
  }
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 10800
  }

  tags = merge(
    local.tags,
    {
      Name = "httpd-target-group"
    },
  )

}

resource "aws_lb_target_group_attachment" "httpd" {
  target_group_arn = aws_lb_target_group.httpd.arn
  target_id        = aws_instance.httpd_instance.id
  port             = 80
}

resource "aws_lb_listener" "http_internal" {

  load_balancer_arn = aws_lb.httpd.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpd.arn
  }

  tags = local.tags

}

resource "aws_lb_listener" "https_internal" {

  load_balancer_arn = aws_lb.httpd.arn
  port              = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate_validation.external_lb_certificate_validation[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpd.arn
  }

  tags = local.tags

}