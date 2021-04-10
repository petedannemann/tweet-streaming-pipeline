provider "aws" {
  region = "${var.region}"
}

data "aws_region" "default" {}

resource "aws_athena_workgroup" "this" {
  name = "athena_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/output/"
    }
  }
}
