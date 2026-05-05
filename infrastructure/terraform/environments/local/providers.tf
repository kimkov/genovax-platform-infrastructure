provider "aws" {
  region = var.aws_region
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    s3 = "http://localhost:4566"
    cognito_idp = "http://localhost:4566"
    kms = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    iam = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sns = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    ecr = "http://localhost:4566"
  }

  default_tags {
    tags = var.common_tags
  }
}

# Secondary provider for simulating S3 replication (required by the s3 module)
provider "aws" {
  alias = "secondary"
  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    s3 = "http://localhost:4566"
    kms = "http://localhost:4566"
  }

  default_tags {
    tags = var.common_tags
  }
}