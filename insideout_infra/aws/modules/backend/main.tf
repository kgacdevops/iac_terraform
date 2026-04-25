# IAM Roles/Policies #

resource "aws_iam_policy" "backend_policy" {
  name        = "${var.prefix}-backend-policy"
  description = "backend function and resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DynamoDBAccess"
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = ["*"]
      },
      {
        Sid      = "CloudWatchAccess"
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backend_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.backend_policy.arn
}

# Lambda Functions #

resource "aws_lambda_function" "backend_api" {
  function_name    = "${var.prefix}-backend-api"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/${var.backend_pkg_path}"
  source_code_hash = filebase64sha256("${path.module}/${var.backend_pkg_path}")
  runtime          = var.lambda_py_version
  handler          = var.backend_lambda_handler
  environment {
    variables = {
        VERSES_DB  = "${var.prefix}-verses-db"
    } 
  }
}

resource "aws_lambda_function" "loaddb_items" {
  function_name    = "${var.prefix}-load-db-items"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/${var.loaddb_pkg_path}"
  source_code_hash = filebase64sha256("${path.module}/${var.loaddb_pkg_path}")
  runtime          = var.lambda_py_version
  handler          = var.loaddb_lambda_handler
  environment {
    variables = {
        VERSES_DB  = "${var.prefix}-verses-db"
    } 
  }
}

# API Gateway #

resource "aws_api_gateway_rest_api" "backend_apigw" {
  name = "${var.prefix}-backend-api"
}

resource "aws_api_gateway_resource" "backend_apigw_resource" {
  rest_api_id = aws_api_gateway_rest_api.backend_apigw.id
  parent_id   = aws_api_gateway_rest_api.backend_apigw.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "backend_apigw_any" {
  rest_api_id   = aws_api_gateway_rest_api.backend_apigw.id
  resource_id   = aws_api_gateway_resource.backend_apigw_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "backend_apigw_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.backend_apigw.id
  resource_id   = aws_api_gateway_resource.backend_apigw_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "backend_apigw_integration_options" {
  rest_api_id = aws_api_gateway_rest_api.backend_apigw.id
  resource_id = aws_api_gateway_resource.backend_apigw_resource.id
  http_method = aws_api_gateway_method.backend_apigw_method_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "backend_apigw_method_response_options" {
  rest_api_id = aws_api_gateway_rest_api.backend_apigw.id
  resource_id = aws_api_gateway_resource.backend_apigw_resource.id
  http_method = aws_api_gateway_method.backend_apigw_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "backend_apigw_integration_response_options" {
  rest_api_id = aws_api_gateway_rest_api.backend_apigw.id
  resource_id = aws_api_gateway_resource.backend_apigw_resource.id
  http_method = aws_api_gateway_method.backend_apigw_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda Integration #

resource "aws_api_gateway_integration" "backend_apigw_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.backend_apigw.id
  resource_id             = aws_api_gateway_resource.backend_apigw_resource.id
  http_method             = aws_api_gateway_method.backend_apigw_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.backend_api.invoke_arn
}

# APIGW Deployment #

resource "aws_api_gateway_deployment" "backend_apigw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.backend_apigw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.backend_apigw_resource,
      aws_api_gateway_method.backend_apigw_any,
      aws_api_gateway_integration.backend_apigw_lambda_integration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "backend_apigw_stage" {
  rest_api_id   = aws_api_gateway_rest_api.backend_apigw.id
  deployment_id = aws_api_gateway_deployment.backend_apigw_deployment.id
  stage_name    = "api"
}

# Lambda Permission #

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.backend_apigw.execution_arn}/*/*"
}

# Dynamo DB #

resource "aws_dynamodb_table" "verses_db" {
  name         = "${var.prefix}-verses-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "verse_reference"

  attribute {
    name = "verse_reference"
    type = "S"
  }
}