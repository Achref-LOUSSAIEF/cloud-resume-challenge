output "cloudfront_domain" {
  value = aws_cloudfront_distribution.my_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.my_distribution.id
}

output "api_endpoint" {
  value = "${aws_apigatewayv2_api.visitor_counter.api_endpoint}/visitors"
}

output "route53_name_servers" {
  description = "Point your domain registrar to these"
  value       = aws_route53_zone.my_zone.name_servers
}

output "s3_bucket_name" {
  value = aws_s3_bucket.resume_bucket.bucket
}