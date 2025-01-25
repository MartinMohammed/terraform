resource "aws_secretsmanager_secret" "mistral_api_key" {
  name        = "MISTRAL_API_KEY"
  description = "API key for Mistral AI service"

  tags = {
    Environment = var.environment
    Project     = "GameJam"
  }
}

# Output the secret ARN for reference
output "mistral_api_key_secret_arn" {
  description = "ARN of the Mistral API Key secret"
  value       = aws_secretsmanager_secret.mistral_api_key.arn
  sensitive   = true
}
