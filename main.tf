data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_tf_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#adding policy to the role
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "s3-scanned-file-mover-policy"
  role = aws_iam_role.lambda_tf_role.id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        sid = "AllowS3Access"
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.source_bucket}"
      },
      {
        sid = "AllowReadAndDeleteFromSource"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.source_bucket}/${var.source_prefix}*"
      },
      {
            sid = "AllowWriteToDestination"
            Action = [
            "s3:PutObject"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:s3:::${var.destination_bucket}/${var.destination_prefix}*"
     }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role" {
  role       = aws_iam_role.lambda_tf_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  
}

resource "aws_lambda_function" "lambda_exec" {
  function_name = "s3-scanned-file-mover-lambda"
  role          = aws_iam_role.lambda_tf_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 60
  memory_size = 128

  depends_on = [
      aws_iam_role_policy.lambda_s3_policy,
      aws_iam_role_policy_attachment.lambda_role
    ]
}

