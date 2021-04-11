output "circleci_iam_access_key_id" {
  value = aws_iam_access_key.circleci.id
}

output "circleci_iam_access_key_secret" {
  value = aws_iam_access_key.circleci.secret
}
