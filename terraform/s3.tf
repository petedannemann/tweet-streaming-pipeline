resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket        = var.s3_bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket" "athena_results_bucket" {
  bucket        = var.athena_s3_bucket_name
  acl           = "private"
  force_destroy = true
}
