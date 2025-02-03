# # Associate WAF Web ACL with the Application Load Balancer (only for prod)
# resource "aws_wafv2_web_acl_association" "alb_waf" {
#   for_each = {
#     for k, v in local.environments : k => v
#     if k == "prod"
#   }

#   resource_arn = aws_lb.ecs_alb[each.key].arn
#   web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
# }
