# ===========================
# 📈 Auto Scaling Group (ASG)
# ===========================
resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg-${var.environment}"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  placement_group           = aws_placement_group.this.id
  vpc_zone_identifier       = var.subnet_ids
  protect_from_scale_in     = true

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  lifecycle {
    ignore_changes = [tag, desired_capacity]
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
}

# ==================
# 🧱 Placement Group
# ==================
resource "aws_placement_group" "this" {
  name     = "${var.name}-pg-${var.environment}"
  strategy = "spread"
}

# ================================
# 🚀 Launch Template (used by ASG)
# ================================
resource "aws_launch_template" "this" {
  name          = "${var.name}-lt-${var.environment}"
  instance_type = var.instance_type
  image_id      = data.aws_ami.al2023_ecs_kernel6plus.image_id
  key_name      = aws_key_pair.this.key_name

  user_data = base64encode(data.template_file.ecs_user_data.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  dynamic "instance_market_options" {
    for_each = var.use_spot == true ? [1] : []
    content {
      market_type = "spot"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ebs_size
      volume_type           = var.ebs_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.this.id]
  }

  tags = {
    Name = "${var.name}-lt-${var.environment}"
  }
}

# ========================
# 🔐 TLS Key Pair Creation
# ========================
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key-${var.environment}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "this" {
  filename        = "${path.root}/keys/${aws_key_pair.this.key_name}.pem"
  content         = tls_private_key.this.private_key_openssh
  file_permission = "0600"
}

# ===========================================================
# 🔍 Fetch public IP of current machine (used for SSH access)
# ===========================================================
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# =================================
# 🔒 Security Group + Ingress Rules
# =================================
resource "aws_security_group_rule" "public_https" {
  count = var.enable_public_https == true ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS"
  security_group_id = aws_security_group.this.id
}
resource "aws_security_group" "this" {
  description = "${var.name} Auto Scalling Group Security Group"
  name        = "${var.name}-asg-sg-${var.environment}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_ssh_from_current_ip ? [1] : []
    content {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [data.http.my_ip.response_body]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_public_ssh ? [1] : []
    content {
      description = "Allow SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-asg-sg-${var.environment}"
  }
}

# =================================
# 🛡️ IAM Role + Profile for ECS EC2
# =================================
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "ecs_ec2_role_policy" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-ecs-instance-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags = {
    Name = "${var.name}-ecs-instance-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.ecs_ec2_role_policy.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-ecs-instance-profile-${var.environment}"
  role = aws_iam_role.this.name
  tags = {
    Name = "${var.name}-ecs-instance-profile-${var.environment}"
  }
}

# ==============================================
# 🧾 ECS Cluster Registration Script (User Data)
# ==============================================
data "template_file" "ecs_user_data" {
  template = file("${path.module}/scripts/ecs_cluster_registration.sh.tpl")
  vars = {
    ecs_cluster_name = var.ecs_cluster_name
  }
}

# =======================================
# 📦 Amazon Linux 2023 ECS Optimized AMIs
# =======================================
data "aws_ami" "al2023_ecs_kernel6plus" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023*-kernel-6*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}
