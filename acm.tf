# # ACM Certificate for the production subdomain
# resource "aws_acm_certificate" "subdomain_cert" {
#   count                     = var.environment == "prod" ? 1 : 0
#   domain_name               = "a.therealfriends.de"
#   validation_method         = "DNS"
#   subject_alternative_names = ["therealfriends.de"]

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Environment = "prod"
#     Project     = var.base_name
#   }
# }

# # Get the hosted zone for therealfriends.de (only needed for prod)
# data "aws_route53_zone" "main" {
#   count = var.environment == "prod" ? 1 : 0
#   name  = "therealfriends.de"
# }

# # Create DNS validation records (only for prod)
# resource "aws_route53_record" "cert_validation" {
#   for_each = var.environment == "prod" ? {
#     for dvo in aws_acm_certificate.subdomain_cert[0].domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   } : {}


#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main[0].zone_id
# }

# # Certificate validation (only for prod)
# resource "aws_acm_certificate_validation" "cert_validation" {
#   count                   = var.environment == "prod" ? 1 : 0
#   certificate_arn         = aws_acm_certificate.subdomain_cert[0].arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }
