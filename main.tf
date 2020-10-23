resource "null_resource" "download_lambda_zip" {
  triggers = {
    version = var.exporter_version
  }

  provisioner "local-exec" {
    command = "curl -L -o ${path.module}/lambda-cloudwatch-export_${var.exporter_version}_linux_amd64.zip https://github.com/gadgetry-io/lambda-cloudwatch-export/releases/download/v${var.exporter_version}/lambda-cloudwatch-export_${var.exporter_version}_linux_amd64.zip"
  }
}

resource "aws_lambda_function" "cloudwatch_export" {
  function_name = var.name
  filename      = "${path.module}/lambda-cloudwatch-export_${var.exporter_version}_linux_amd64.zip"
  role          = aws_iam_role.cloudwatch_export.arn
  handler       = "cloudwatch-export"
  runtime       = "go1.x"

  environment {
    variables = {
      environment = terraform.workspace
    }
  }

  depends_on = [null_resource.download_lambda_zip]
}

resource "aws_cloudwatch_event_rule" "cloudwatch_export" {
  name                = aws_lambda_function.cloudwatch_export.function_name
  description         = "CloudWatch log exports for ${var.log_group}"
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = aws_lambda_function.cloudwatch_export.function_name
  rule      = aws_cloudwatch_event_rule.cloudwatch_export.name
  arn       = aws_lambda_function.cloudwatch_export.arn

  input = <<EOF
{"s3_bucket":"${var.s3_bucket}", "s3_prefix":"${var.s3_prefix}", "log_group":"${var.log_group}"}
EOF
}

resource "aws_lambda_permission" "events" {
  statement_id  = aws_lambda_function.cloudwatch_export.function_name
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_export.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudwatch_export.arn
}

resource "aws_iam_role" "cloudwatch_export" {
  name               = var.name
  description        = "Lambda role for CloudWatch Log exports"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_export_assume_role.json
}

data "aws_iam_policy_document" "cloudwatch_export_assume_role" {
  statement {
    sid     = "BasicLambdaExecution"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_export" {
  name   = var.name
  role   = aws_iam_role.cloudwatch_export.id
  policy = data.aws_iam_policy_document.cloudwatch_export_inline.json
}

data "aws_iam_policy_document" "cloudwatch_export_inline" {
  statement {
    actions   = ["cloudwatch:*", "logs:*"]
    resources = ["*"]
  }
}
