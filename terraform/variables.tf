variable "region" {
  description = "AWS Region to deploy in"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for kinesis firehose to write to"
  default     = "kinesis-firehose-test-12345"
}

variable "kinesis_firehose_stream_name" {
  description = "Name of the Kinesis Firehose Delivery stream"
  default     = "twitter"
}
