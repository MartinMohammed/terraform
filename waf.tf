# Create IP rate limiting rule
resource "aws_wafv2_rule_group" "rate_limiting" {
  name     = "${local.base_name}-rate-limit"
  scope    = "REGIONAL"
  capacity = 2 # Rate-based rule uses 2 WCUs

  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100 # Requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitRuleGroup"
    sampled_requests_enabled   = true
  }
}

# Create blocked domains rule
resource "aws_wafv2_regex_pattern_set" "blocked_domains" {
  name  = "${local.base_name}-blocked-domains"
  scope = "REGIONAL"

  regular_expression {
    regex_string = "^.*\\.evil\\.com$"
  }
  regular_expression {
    regex_string = "^.*\\.malicious\\.org$"
  }
}

# Create WAF ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "${local.base_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Block bad domains
  rule {
    name     = "BlockedDomains"
    priority = 1

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.blocked_domains.arn
        field_to_match {
          single_header {
            name = "host"
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
      metric_name                = "BlockedDomainsRule"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting
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

# Enable WAF logging
resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}
