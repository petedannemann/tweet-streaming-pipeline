data "aws_iam_policy_document" "kinesis_firehose_stream_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "kinesis_firehose_access_bucket_assume_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.kinesis_firehose_stream_bucket.arn,
      "${aws_s3_bucket.kinesis_firehose_stream_bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "kinesis_firehose_access_glue_assume_policy" {
  statement {
    effect    = "Allow"
    actions   = ["glue:GetTableVersions"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "kinesis_firehose_stream_role" {
  name               = "kinesis_firehose_stream_role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_firehose_stream_assume_role.json
}

resource "aws_iam_role_policy" "kinesis_firehose_access_bucket_policy" {
  name   = "kinesis_firehose_access_bucket_policy"
  role   = aws_iam_role.kinesis_firehose_stream_role.name
  policy = data.aws_iam_policy_document.kinesis_firehose_access_bucket_assume_policy.json
}

resource "aws_iam_role_policy" "kinesis_firehose_access_glue_policy" {
  name   = "kinesis_firehose_access_glue_policy"
  role   = aws_iam_role.kinesis_firehose_stream_role.name
  policy = data.aws_iam_policy_document.kinesis_firehose_access_glue_assume_policy.json
}

data "aws_iam_policy_document" "cloudwatch_logs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.${length(var.region) > 0 ? var.region : data.aws_region.default.name}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_assume_policy" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = [aws_kinesis_firehose_delivery_stream.kinesis_firehose_stream.arn]
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  name               = "cloudwatch_logs_role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_logs_assume_role.json
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name   = "cloudwatch_logs_policy"
  role   = aws_iam_role.cloudwatch_logs_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_assume_policy.json
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "twitter_stream_ecs_execution_role" {
  name               = "twitter_stream_ecs_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_access_ecr_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_role_policy" "ecs_access_ecr_policy" {
  name   = "ecs_access_ecr_policy"
  role   = aws_iam_role.twitter_stream_ecs_execution_role.name
  policy = data.aws_iam_policy_document.ecs_access_ecr_policy.json
}

data "aws_iam_policy_document" "authorize_ecr_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_authorize_ecr_policy" {
  name   = "ecs_authorize_ecr_policy"
  role   = aws_iam_role.twitter_stream_ecs_execution_role.name
  policy = data.aws_iam_policy_document.authorize_ecr_policy.json
}

data "aws_iam_policy_document" "ecs_access_secrets_manager_policy" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecret", "secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.this.arn]
  }
}

resource "aws_iam_role_policy" "ecs_access_secrets_manager_policy" {
  name   = "ecs_access_secrets_manager_policy"
  role   = aws_iam_role.twitter_stream_ecs_execution_role.name
  policy = data.aws_iam_policy_document.ecs_access_secrets_manager_policy.json
}

resource "aws_iam_role" "twitter_stream_ecs_task_role" {
  name               = "twitter_stream_ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_publish_to_firehose_policy" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
    resources = [aws_kinesis_firehose_delivery_stream.kinesis_firehose_stream.arn]
  }
}

resource "aws_iam_role_policy" "ecs_publish_to_firehose_policy" {
  name   = "ecs_publish_to_firehose_policy"
  role   = aws_iam_role.twitter_stream_ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_publish_to_firehose_policy.json
}

data "aws_iam_policy_document" "ecs_write_to_cloudwatch_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task_write_to_cloudwatch_policy" {
  name   = "ecs_task_write_to_cloudwatch_policy"
  role   = aws_iam_role.twitter_stream_ecs_task_role.name
  policy = data.aws_iam_policy_document.ecs_write_to_cloudwatch_policy.json
}

resource "aws_iam_role_policy" "ecs_execution_write_to_cloudwatch_policy" {
  name   = "ecs_execution_write_to_cloudwatch_policy"
  role   = aws_iam_role.twitter_stream_ecs_execution_role.name
  policy = data.aws_iam_policy_document.ecs_write_to_cloudwatch_policy.json
}

resource "aws_iam_user" "circleci_user" {
  name = "circleci_user"
}

data "aws_iam_policy_document" "circleci_access_ecr_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:SetRepositoryPolicy"
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_user_policy" "circleci_access_ecr_policy" {
  name   = "circleci_access_ecr_policy"
  user   = aws_iam_user.circleci_user.name
  policy = data.aws_iam_policy_document.circleci_access_ecr_policy.json
}

resource "aws_iam_user_policy" "circleci_authorize_ecr_policy" {
  name   = "circleci_authorize_ecr_policy"
  user   = aws_iam_user.circleci_user.name
  policy = data.aws_iam_policy_document.authorize_ecr_policy.json
}

resource "aws_iam_access_key" "circleci" {
  user = aws_iam_user.circleci_user.name
}
