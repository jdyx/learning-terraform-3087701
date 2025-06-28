data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner] # Bitnami
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.0"

  name     = "${var.environment.name}-blog"
  min_size            = var.asg_min
  max_size            = var.asg_max

  vpc_zone_identifier = module.blog_vpc.public_subnets

  security_groups = [module.blog_sg.security_group_id]
  traffic_source_attachments = {
    blog_alb = {
      traffic_source_identifier = module.blog_alb.target_groups["blog_asg"].arn
      traffic_source_type = "elbv2"
    }
  }
  image_id               = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.13.0"

  name = "${var.environment.name}-blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  listeners = {
    blog_http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "blog_asg"
      }
    }
  }

  target_groups = {
    blog_asg = {
      name_prefix      = "blog-"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      # Required argument to attach to the ASG later.
      create_attachment = false
    }
 }

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id  = module.blog_vpc.vpc_id
  name    = "blog"
  ingress_rules = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}