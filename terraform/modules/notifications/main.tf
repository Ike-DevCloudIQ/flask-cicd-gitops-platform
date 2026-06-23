locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────
# SNS Topic — all alerts go here
# ──────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ──────────────────────────────────────────
# CloudWatch alarms — Jenkins master
# ──────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "master_cpu_high" {
  alarm_name          = "${local.name_prefix}-jenkins-master-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Jenkins master CPU above 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.master_instance_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "master_status_check" {
  alarm_name          = "${local.name_prefix}-jenkins-master-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Jenkins master failed EC2 status check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.master_instance_id
  }

  tags = local.common_tags
}

# ──────────────────────────────────────────
# CloudWatch alarms — Jenkins slave
# ──────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "slave_cpu_high" {
  alarm_name          = "${local.name_prefix}-jenkins-slave-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Jenkins slave CPU above 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.slave_instance_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "slave_status_check" {
  alarm_name          = "${local.name_prefix}-jenkins-slave-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Jenkins slave failed EC2 status check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.slave_instance_id
  }

  tags = local.common_tags
}
