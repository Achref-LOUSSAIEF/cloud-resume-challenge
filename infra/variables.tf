variable "domain_name" {
  type    = string
  default = "achrefls.me"
}

variable "s3_bucket_name" {
  type    = string
  default = "achref-cloud-resume-challenge"
}

variable "acm_certificate_arn" {
  type      = string
  sensitive = true
}

variable "lambda_role_arn" {
  type      = string
  sensitive = true
}
variable "lambda_source_code_hash" {
  description = "Base64 SHA256 hash of the lambda zip, used to trigger redeployment"
  type        = string
  default     = null
}