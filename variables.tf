variable "name" {
  description = "short description of the logs you're exporting"
  default     = "cloudwatch-export"
}

variable "log_group" {
  description = "Name of Cloudwatch Log Group to export to S3"
}

variable "s3_bucket" {
  description = "bucket logs will be put into"
}

variable "exporter_version" {
  description = "Version of the cloudwatch-exporter to deploy. Defaults to the latest version available"
  default     = "0.0.2"
}

variable "s3_prefix" {
  description = "prefix for your logs"
  default     = "cloudwatch-export"
}

variable "schedule" {
  description = "CloudWatch schedule for export"
  default     = "cron(15 12 * * ? *)"
}
