resource "aws_ecs_cluster" "this" {
  name = "twitter-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family             = "twitter"
  execution_role_arn = aws_iam_role.twitter_stream_ecs_role.arn
  container_definitions = jsonencode([
    {
      name      = "tweet-streaming-pipeline"
      image     = aws_ecr_repository.this.name
      cpu       = 1
      memory    = 512
      essential = true
      secrets = [
        {
          "name" : "STREAM_NAME",
          "valueFrom" : aws_secretsmanager_secret.this.arn
        },
        {
          "name" : "TWITTER_API_KEY",
          "valueFrom" : aws_secretsmanager_secret.this.arn
        },
        {
          "name" : "TWITTER_API_SECRET_KEY",
          "valueFrom" : aws_secretsmanager_secret.this.arn
        },
        {
          "name" : "TWITTER_ACCESS_TOKEN",
          "valueFrom" : aws_secretsmanager_secret.this.arn
        },
        {
          "name" : "TWITTER_ACCESS_TOKEN_SECRET",
          "valueFrom" : aws_secretsmanager_secret.this.arn
        }
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "twitter-stream"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
}
