locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== EC2 APPLICATION SERVERS =====
resource "aws_instance" "app" {
    count = length(var.app_subnet_ids)

    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = var.app_subnet_ids[count.index]
    vpc_security_group_ids = [var.ec2_security_group_id]

    associate_public_ip_address = false

    user_data = <<-EOF
        #!/bin/bash
        yum update -y

        yum install -y httpd

        systemctl start httpd
        systemctl enable httpd

        echo "<h1>Three-Tier Architecture App Server $(hostname)</h1>" > /var/www/html/index.html
        EOF

    tags = {
        Name = "${local.name_prefix}-app-server-${count.index + 1}"
        Environment = var.environment
        Project = var.project_name
    }
}

# ===== ATTACH EC2 TO TARGET GROUP =====
resource "aws_lb_target_group_attachment" "app" {
    count = length(var.app_subnet_ids)

    target_group_arn = var.target_group_arn
    target_id = aws_instance.app[count.index].id
    port = 80
}