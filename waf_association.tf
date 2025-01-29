# Associate WAF Web ACL with the Application Load Balancer
resource "aws_wafv2_web_acl_association" "alb_waf" {
  for_each = local.environments

  resource_arn = aws_lb.ecs_alb[each.key].arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}
