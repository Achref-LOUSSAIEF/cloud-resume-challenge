# ─── S3 ──────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.s3_bucket_name
  tags   = { project = "cloud-resume-challenge" }
}

resource "aws_s3_bucket_public_access_block" "resume_bucket" {
  bucket                  = aws_s3_bucket.resume_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "resume_bucket" {
  bucket = aws_s3_bucket.resume_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_policy" "resume_bucket" {
  bucket = aws_s3_bucket.resume_bucket.id
  policy = data.aws_iam_policy_document.s3_cloudfront_policy.json
}

data "aws_iam_policy_document" "s3_cloudfront_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.resume_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.my_distribution.arn]
    }
  }
}

# ─── CLOUDFRONT ──────────────────────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  http_version        = "http2"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  price_class = "PriceClass_100"

  custom_error_response {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code         = 200
    error_caching_min_ttl = 300
  }

  tags = { project = "cloud-resume-challenge" }
}

# ─── ROUTE 53 ────────────────────────────────────────────────────────────────

resource "aws_route53_zone" "my_zone" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.my_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.my_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.my_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.my_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# ─── LAMBDA ──────────────────────────────────────────────────────────────────

resource "aws_lambda_function" "cloud_resume_api" {
  provider         = aws.us_east_1
  function_name    = "cloud-resume-api"
  role             = var.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  architectures    = ["x86_64"]
  timeout          = 3
  memory_size      = 128
  s3_bucket        = var.s3_bucket_name
  s3_key           = "lambda/cloud-resume-api.zip"
  source_code_hash = var.lambda_source_code_hash

  ephemeral_storage { size = 512 }
  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/cloud-resume-api"
  }
  tags = { project = "cloud-resume-challenge" }
}

# ─── API GATEWAY ─────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "visitor_counter" {
  provider      = aws.us_east_1
  name          = "visitor-counter"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["Content-Type"]
  }
  tags = { project = "cloud-resume-challenge" }
}

resource "aws_apigatewayv2_integration" "lambda" {
  provider               = aws.us_east_1
  api_id                 = aws_apigatewayv2_api.visitor_counter.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cloud_resume_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_visitors" {
  provider  = aws.us_east_1
  api_id    = aws_apigatewayv2_api.visitor_counter.id
  route_key = "GET /visitors"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  provider    = aws.us_east_1
  api_id      = aws_apigatewayv2_api.visitor_counter.id
  name        = "$default"
  auto_deploy = true
  tags        = { project = "cloud-resume-challenge" }
}

resource "aws_lambda_permission" "apigw" {
  provider      = aws.us_east_1
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloud_resume_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter.execution_arn}/*/*"
}