resource "aws_ecs_cluster" "this" {
  name = "twitter-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "twitter"
  execution_role_arn       = aws_iam_role.twitter_stream_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.twitter_stream_ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "tweet-streaming-pipeline"
      image     = aws_ecr_repository.this.repository_url
      cpu       = 256
      memory    = 512
      essential = true
      environment = [
        {
          "name" : "STREAM_NAME",
          "value" : aws_kinesis_firehose_delivery_stream.kinesis_firehose_stream.name
        }
      ]
      secrets = [
        {
          "name" : "TWITTER_API_KEY",
          "valueFrom" : "${aws_secretsmanager_secret.this.arn}:twitter_api_key::"
        },
        {
          "name" : "TWITTER_API_SECRET_KEY",
          "valueFrom" : "${aws_secretsmanager_secret.this.arn}:twitter_api_secret_key::"
        },
        {
          "name" : "TWITTER_ACCESS_TOKEN",
          "valueFrom" : "${aws_secretsmanager_secret.this.arn}:twitter_access_token::"
        },
        {
          "name" : "TWITTER_ACCESS_TOKEN_SECRET",
          "valueFrom" : "${aws_secretsmanager_secret.this.arn}:twitter_access_token_secret::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "twitter-stream"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "twitter-stream"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  # Change this to 1 to start cluster
  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_subnet.id]
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = false
  }
}
