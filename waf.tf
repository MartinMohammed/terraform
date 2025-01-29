resource "aws_wafv2_web_acl" "web_acl" {
  name        = var.web_acl_name
  description = var.web_acl_description
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  # Rule to allow traffic only from Hugging Face domain
  rule {
    name     = "AllowHuggingFaceDomain"
    priority = 1

    override_action {
      none {}
    }

    statement {
      byte_match_statement {
        field_to_match {
          single_header {
            name = "origin"
          }
        }
        positional_constraint = "EXACTLY"
        search_string         = "https://huggingface.co"
        text_transformation {
          priority = 1
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowHuggingFaceDomain"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Bad bot detection rule
  rule {
    name     = var.rule_name
    priority = 3

    action {
      block {}
    }

    statement {
      byte_match_statement {
        field_to_match {
          single_header {
            name = "User-Agent"
          }
        }
        positional_constraint = "STARTS_WITH"
        search_string         = "BadBot"
        text_transformation {
          priority = 1
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadBotRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACLMetrics"
    sampled_requests_enabled   = true
  }
}
