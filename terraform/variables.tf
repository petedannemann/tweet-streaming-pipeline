variable "region" {
  description = "AWS Region to deploy in"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for kinesis firehose to write to"
  default     = "kinesis-firehose-test-12345"
}

variable "s3_prefix" {
  description = "Prefix to add to files written out by Kinesis"
  default     = "data"
}

variable "athena_s3_bucket_name" {
  description = "Name of S3 bucket for athena query results"
  default     = "twitter-athena-results-12345"
}

variable "kinesis_firehose_stream_name" {
  description = "Name of the Kinesis Firehose Delivery stream"
  default     = "twitter"
}

variable "glue_catalog_database_name" {
  description = "Name of Glue Catalog Database"
  default     = "twitter"
}

variable "glue_catalog_table_name" {
  description = "Name of Glue Catalog Table"
  default     = "tweets"
}

variable "secrets" {
  # Should have keys of TWITTER_API_KEY, TWITTER_API_SECRET_KEY, TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_TOKEN_SECRET
  type = map(string)
}
