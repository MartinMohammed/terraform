# Create IP rate limiting rule
resource "aws_wafv2_rule_group" "rate_limiting" {
  name     = "${local.base_name}-rate-limit"
  scope    = "REGIONAL"
  capacity = 30

  rule {
    # The capacity parameter in a rule group represents the total processing capacity of the rule group,
    # measured in Web ACL Capacity Units (WCU). Each type of rule consumes a different amount of capacity,
    # and the total capacity of all rules in a rule group cannot exceed the specified capacity value.
    name     = "rate-limit"
    priority = 1

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = 75 # Requests per 5 minutes per IP which is 15 request per minute 
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric" # Metric name for rate limiting
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitRuleGroupMetric" # Metric name for rate limiting rule group
    sampled_requests_enabled   = true
  }
}

# Create allowed domains rule
resource "aws_wafv2_regex_pattern_set" "allowed_domains" {
  name  = "${local.base_name}-allowed-domains"
  scope = "REGIONAL"

  regular_expression {
    regex_string = "^.*\\.huggingface\\.co$"
  }
  regular_expression {
    regex_string = "^.*\\.mistral\\.ai$"
  }
  regular_expression {
    regex_string = "^.*\\.elevenlabs\\.io$"
  }
}

# Create WAF ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.base_name}-waf"
  scope = "REGIONAL" # Regional WAF is used for ALB

  default_action {
    block {}
  }

  rule {
    name     = "AllowedDomains" # referer header is used to identify the domain of the request
    priority = 1

    action {
      allow {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.allowed_domains.arn
        field_to_match {
          single_header {
            name = "referer"
          }
        }
        text_transformation {
          priority = 1
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowedDomainsRule"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.rate_limiting.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFWebACL"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  for_each     = local.environments
  resource_arn = aws_lb.ecs_alb[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# Enable WAF logging to CloudWatch
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/waf/${local.base_name}"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  log_destination_configs = ["${aws_cloudwatch_log_group.waf.arn}:*"]
  resource_arn            = aws_wafv2_web_acl.main.arn
}
