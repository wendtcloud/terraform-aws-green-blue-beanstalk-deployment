resource "aws_elastic_beanstalk_environment" "blue_deployment" {
  name                = "blue-deployment-environment"
  application         = aws_elastic_beanstalk_application.beanstalk_application.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.12.4 running Node.js 26"
  version_label       = aws_elastic_beanstalk_application_version.v1.name

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.arn
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "3"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "70"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "20"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  tags = {
    Version = "1.0"
  }
}

resource "aws_lb_target_group" "blue_lb_target_group" {
  name        = "blue-deployment-target-group"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "blue_lb_sg" {
  name        = "lb-security-group"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

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

resource "aws_lb" "blue_deployment_lb" {
  name               = "blue-deployment-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.blue_lb_sg.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]
}

resource "aws_elastic_beanstalk_application_version" "v1" {
  name        = "app-v1"
  application = aws_elastic_beanstalk_application.beanstalk_application.name
  bucket      = aws_s3_bucket.eb_artifacts.id
  key         = aws_s3_object.app_v1.key
}
