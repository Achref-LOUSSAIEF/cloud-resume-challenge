terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  
    }
  }
}


resource "aws_s3_bucket" "resume_bucket" {
  bucket = "achref-cloud-resume-challenge"

  tags = {
    project = "cloud-resume-challenge"
  }
}

resource "aws_route53_zone" "my_zone" {
  name = "achrefls.me."
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "cfbuck1234.s3.us-east-1.amazonaws.com"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name              = "achref-cloud-resume-challenge.s3.eu-north-1.amazonaws.com"
    origin_id                = "S3Origin"
    origin_access_control_id = "EMN3H7KUFQN1U"
  }

  enabled             = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  http_version        = "http2"

  aliases = ["achrefls.me", "www.achrefls.me"]

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress              = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:600627345568:certificate/4dda2583-075e-41c4-a028-ccee20fbbf4c"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  price_class = "PriceClass_All"

  custom_error_response {
    error_code            = 404
    response_page_path    = "/index.html"
    response_code        = 200
    error_caching_min_ttl = 300
  }
}

resource "aws_lambda_function" "cloud_resume_api" {
  provider      = aws.us_east_1
  function_name = "cloud-resume-api"
  role          = "arn:aws:iam::600627345568:role/service-role/cloud-resume-api-role-854lmm7p"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  architectures = ["x86_64"]
  timeout       = 3
  memory_size   = 128

  ephemeral_storage {
    size = 512
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/cloud-resume-api"
  }
}


resource "aws_apigatewayv2_api" "visitor_counter" {
  provider        = aws.us_east_1  
  name           = "visitor-counter"
  protocol_type  = "HTTP"

  api_key_selection_expression = "$request.header.x-api-key"
  route_selection_expression   = "$request.method $request.path"
}
