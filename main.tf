terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.39"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region_name
}



#################################
# Lambdas
##################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

#########
## Signup
###

data "archive_file" "lambda_signup" {
  type        = "zip"
  source_file = "lambdas/pre_signup.py"
  output_path = "lambda_pre_signup.zip"
}

resource "aws_lambda_function" "lambda_signup" {
  filename      = "lambda_pre_signup.zip"
  function_name = "pre-signup2"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "pre_signup.lambda_handler"

  source_code_hash = data.archive_file.lambda_signup.output_base64sha256

  runtime = "python3.12"
}

###########
## create auth
###

data "archive_file" "lambda_create_auth" {
  type        = "zip"
  source_file = "lambdas/create_auth_challenge.py"
  output_path = "lambda_create_auth_challenge.zip"
}

resource "aws_lambda_function" "lambda_create_auth" {
  filename      = "lambda_create_auth_challenge.zip"
  function_name = "create-auth-challenge"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "create_auth_challenge.lambda_handler"

  source_code_hash = data.archive_file.lambda_create_auth.output_base64sha256

  runtime = "python3.12"
}

##########
## define auth
####

data "archive_file" "lambda_define_auth" {
  type        = "zip"
  source_file = "lambdas/define_auth_challenge.py"
  output_path = "lambda_define_auth_challenge.zip"
}

resource "aws_lambda_function" "lambda_define_auth" {
  filename      = "lambda_define_auth_challenge.zip"
  function_name = "define-auth-challenge"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "define_auth_challenge.lambda_handler"

  source_code_hash = data.archive_file.lambda_define_auth.output_base64sha256

  runtime = "python3.12"
}

###########
## verify auth
####

data "archive_file" "lambda_verify_auth" {
  type        = "zip"
  source_file = "lambdas/verify_auth_challenge.py"
  output_path = "lambda_verify_auth_challenge.zip"
}

resource "aws_lambda_function" "lambda_verify_auth" {
  filename      = "lambda_verify_auth_challenge.zip"
  function_name = "verify-auth-challenge"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "verify_auth_challenge.lambda_handler"

  source_code_hash = data.archive_file.lambda_verify_auth.output_base64sha256

  runtime = "python3.12"
}


#################################
# Cognito
##################

resource "aws_cognito_user_pool" "pool" {
  alias_attributes           = null
  auto_verified_attributes   = ["email"]
  deletion_protection        = "ACTIVE"
  email_verification_message = null
  email_verification_subject = null
  mfa_configuration          = "OFF"
  name                       = "fiap-58"
  sms_authentication_message = null
  sms_verification_message   = null
  tags                       = {}
  tags_all                   = {}
  username_attributes        = ["email"]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  email_configuration {
    configuration_set      = null
    email_sending_account  = "COGNITO_DEFAULT"
    from_email_address     = null
    reply_to_email_address = null
    source_arn             = null
  }
  lambda_config {
    create_auth_challenge          = aws_lambda_function.lambda_create_auth.arn
    custom_message                 = null
    define_auth_challenge          = aws_lambda_function.lambda_define_auth.arn
    kms_key_id                     = null
    post_authentication            = null
    post_confirmation              = null
    pre_authentication             = null
    pre_sign_up                    = aws_lambda_function.lambda_signup.arn
    pre_token_generation           = null
    user_migration                 = null
    verify_auth_challenge_response = aws_lambda_function.lambda_verify_auth.arn
  }
  password_policy {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "cpf"
    required                 = false
    string_attribute_constraints {
      max_length = null
      min_length = null
    }
  }
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }
  username_configuration {
    case_sensitive = false
  }
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_message         = null
    email_message_by_link = null
    email_subject         = null
    email_subject_by_link = null
    sms_message           = null
  }
}




############################
## API Gateway + VPC Link
#####

data "aws_lb" "aws_lb" {
}

resource "aws_api_gateway_vpc_link" "vpc_link" {
  name        = "fiap-58-vpc-link"
  target_arns = [data.aws_lb.aws_lb.arn]
}


resource "aws_api_gateway_rest_api" "rest_api" {
  name = "fiap-58-api-gtw"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "authorizer" {
  authorizer_credentials           = null
  authorizer_result_ttl_in_seconds = 3000
  authorizer_uri                   = null
  identity_source                  = "method.request.header.cognitoToken"
  identity_validation_expression   = null
  name                             = "fiap-58"
  provider_arns                    = [aws_cognito_user_pool.pool.arn]
  rest_api_id                      = aws_api_gateway_rest_api.rest_api.id
  type                             = "COGNITO_USER_POOLS"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "api_integration" {
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = aws_api_gateway_method.any.http_method
  resource_id             = aws_api_gateway_resource.api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  connection_type         = "VPC_LINK"
  type                    = "HTTP_PROXY"
  connection_id           = aws_api_gateway_vpc_link.vpc_link.id
  uri                     = "http://fiap58.com/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.any.id,
      aws_api_gateway_integration.api_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stg" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "stg"
}
