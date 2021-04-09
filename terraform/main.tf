provider "aws" {
  region = "${var.region}"
}

data "aws_region" "default" {}

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"
}

resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group" {
  name = "/aws/kinesisfirehose/${var.kinesis_firehose_stream_name}"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream" {
  log_group_name = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
  name           = "S3Delivery"
}

data "aws_caller_identity" "current" {}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_stream" {
  name        = var.kinesis_firehose_stream_name
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_stream_role.arn
    bucket_arn = aws_s3_bucket.kinesis_firehose_stream_bucket.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name
    }
  }
}
