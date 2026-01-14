# CloudWatch Log Groups - Reference existing ones if they exist

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when ALB has unhealthy hosts"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${local.prefix}-alb-unhealthy-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${local.prefix}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when ALB response time is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${local.prefix}-alb-response-time-alarm"
  }
}

# CloudWatch Alarms for EKS
resource "aws_cloudwatch_metric_alarm" "eks_cpu_utilization" {
  alarm_name          = "${local.prefix}-eks-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when EKS nodes have high CPU utilization"
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.prefix}-eks-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "eks_memory_utilization" {
  alarm_name          = "${local.prefix}-eks-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when EKS nodes have high memory utilization"
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${local.prefix}-eks-memory-alarm"
  }
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "phishguard" {
  dashboard_name = "${local.prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }],
            [".", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }],
            [".", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS Node Resources"
        }
      }
    ]
  })
}

# SNS Topic for Alarms - Skip if it exists, create with ignore_errors
resource "aws_sns_topic" "phishguard_alerts" {
  name = "${local.prefix}-alerts"

  tags = {
    Name = "${local.prefix}-alerts-topic"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# CloudWatch Alarm Action for SNS
resource "aws_cloudwatch_metric_alarm" "alb_requests_4xx" {
  alarm_name          = "${local.prefix}-alb-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "Alert when ALB receives many 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${local.prefix}-alb-4xx-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_requests_5xx" {
  alarm_name          = "${local.prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when ALB receives many 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${local.prefix}-alb-5xx-alarm"
  }
}

# Outputs
output "cloudwatch_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.phishguard.dashboard_name}"
  description = "URL to CloudWatch Dashboard"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.phishguard_alerts.arn
  description = "SNS Topic ARN for alerts"
}
