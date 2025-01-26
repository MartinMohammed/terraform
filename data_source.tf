# Retrieve the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use the first available subnet
data "aws_subnet" "selected_subnet" {
  id = tolist(data.aws_subnets.default.ids)[0]
}

# Retrieve the default security group within the default VPC
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# Retrieve the default subnets in the default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
