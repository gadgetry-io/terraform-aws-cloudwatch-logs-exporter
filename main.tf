resource "null_resource" "download_lambda_zip" {
  triggers {
    version = "${var.exporter_version}"
  }

  provisioner "local-exec" {
    command = "curl -L -o ${path.module}/cloudwatch-export-${var.exporter_version}.zip https://justmiles.keybase.pub/artifacts/cloudwatch-export/v0.0.1.zip?dl=1"
  }
}

resource "aws_lambda_function" "cloudwatch_export" {
  function_name = "${var.name}"
  filename      = "${path.module}/cloudwatch-export-${null_resource.download_lambda_zip.triggers.version}.zip"
  role          = "${aws_iam_role.cloudwatch_export.arn}"
  handler       = "cloudwatch-export"
  runtime       = "go1.x"

  environment {
    variables {
      environment = "${terraform.workspace}"
    }
  }

  depends_on = ["null_resource.download_lambda_zip"]
}

resource "aws_cloudwatch_event_rule" "cloudwatch_export" {
  name                = "${aws_lambda_function.cloudwatch_export.function_name}"
  schedule_expression = "${var.schedule}"
}

resource "aws_iam_role" "cloudwatch_export" {
  name               = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatch_export_assume_role.json}"
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
  name = "${var.name}"
  role = "${aws_iam_role.cloudwatch_export.id}"

  policy = "${data.aws_iam_policy_document.cloudwatch_export_inline.json}"
}

data "aws_iam_policy_document" "cloudwatch_export_inline" {
  statement {
    actions   = ["cloudwatch:*", "logs:*"]
    resources = ["*"]
  }
}
