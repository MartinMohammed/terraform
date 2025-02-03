# resource "aws_secretsmanager_secret" "mistral_api_key" {
#   name        = "MISTRAL_API_KEY"
#   description = "API key for Mistral AI service"
# }

# # Output the secret ARN for reference
# output "mistral_api_key_secret_arn" {
#   description = "ARN of the Mistral API Key secret"
#   value       = aws_secretsmanager_secret.mistral_api_key.arn
#   sensitive   = true
# }

# resource "aws_secretsmanager_secret" "eleven_labs_api_key" {
#   name        = "ELEVEN_LABS_API_KEY"
#   description = "API key for ELEVEN LABS AI service"
# }

# # Output the secret ARN for reference
# output "eleven_labs_api_key_secret_arn" {
#   description = "ARN of the ELEVEN LABS API Key secret"
#   value       = aws_secretsmanager_secret.eleven_labs_api_key.arn
#   sensitive   = true
# }
