// Bastion - to be removed in the future
resource "aws_security_group" "bastion" {
  count       = var.install_bastion == true ? 1 : 0
  name        = "${var.name}-BastionSecurityGroup"
  description = "SSH from Anywhere, everything from inner network"
  vpc_id      = aws_vpc.base.id

  tags = {
    Name = "${var.name}-BastionSecurityGroup"
  }
}

resource "aws_security_group_rule" "bastion-ingress" {
  count             = var.install_bastion == true ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "bastion-egress" {
  count             = var.install_bastion == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${var.name}-bastion-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_policy_attachments" {
  count = length(var.bastion_role_policies)

  role       = aws_iam_role.bastion.name
  policy_arn = var.bastion_role_policies[count.index]
}

resource "aws_launch_configuration" "bastion" {
  count                       = var.install_bastion == true ? 1 : 0
  name                        = "${var.name}-bastion"
  image_id                    = var.bastion_ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.arn
  user_data                   = file("${path.module}/data/user_data.bastion.sh")

  security_groups = [
    aws_security_group.bastion[0].id,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  count                = var.install_bastion == true ? 1 : 0
  name                 = "${var.name}-BastionAutoScalingGroup"
  max_size             = 2
  min_size             = 1
  launch_configuration = aws_launch_configuration.bastion[0].name
  vpc_zone_identifier  = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_b.id,
  ]
  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "${var.name}-bastion"
    propagate_at_launch = true
  }
}
