variable "source_bucket" {
  description = "The name of the S3 bucket to be accessed by the Lambda function"
  type        = string
}

variable "source_prefix" {
  description = "The prefix (folder path) in the source S3 bucket to be accessed by the Lambda function"
  type        = string
}

variable "destination_bucket" {
  description = "The name of the S3 bucket to which files will be moved by the Lambda function"
  type        = string
}

variable "destination_prefix" {
  description = "The prefix (folder path) in the destination S3 bucket to which files will be moved by the Lambda function"
  type        = string
}