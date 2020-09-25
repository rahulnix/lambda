provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}


// # VPC resource
// resource "aws_vpc" "myvpc" {
//   cidr_block           = "10.0.0.0/16"
//   enable_dns_support   = true
//   enable_dns_hostnames = true
//   instance_tenancy     = "default"
//   tags = {
//     Name = "myvpc"
//   }
// }

// resource "aws_subnet" "PriSub" {
//   vpc_id     = aws_vpc.myvpc.id
//   cidr_block = "10.0.1.0/24"

//   tags = {
//     Name = "Main"
//   }
// }

// resource "aws_security_group" "allow_tls" {
//   name        = "allow_tls"
//   description = "Allow TLS inbound traffic"
//   vpc_id      = aws_vpc.myvpc.id

//   ingress {
//     description = "TLS from VPC"
//     from_port   = 443
//     to_port     = 443
//     protocol    = "tcp"
//     cidr_blocks = [aws_vpc.myvpc.cidr_block]
//   }

//   egress {
//     from_port   = 0
//     to_port     = 0
//     protocol    = "-1"
//     cidr_blocks = ["0.0.0.0/0"]
//   }

//   tags = {
//     Name = "allow_tls"
//   }
// }

// #------------------------------------------------------

// resource "aws_iam_role_policy" "lambda_policy" {
//   name = "lambda_policy"
//   role = aws_iam_role.lambda_role.id

//   policy = file("iam/policy.json")
// }
// #------------------------------------------------------
// resource "aws_iam_role" "lambda_role" {
//   name = "lambda_role"

//   assume_role_policy = file("iam/role.json")
// }
// #------------------------------------------------------
// data "archive_file" "project" {
//   type        = "zip"
//   source_file = "project.py"
//   output_path = "output/project.zip"
// }

#------------------------------------------------------

resource "aws_lambda_function" "test_lambda" {
  filename      = "output/project.zip"
  function_name = "project"
  // role          = aws_iam_role.lambda_role.arn
  role        = "arn:aws:iam::590462871086:role/DataDev_Lambda_Test"
  handler     = "project.hello"
  memory_size = 128
  publish     = true
  timeout     = "60"

  #source_code_hash = filebase64sha256("output/project.zip")

  runtime = "python3.8"

  // vpc_config {
  //   # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
  //   subnet_ids         = [aws_subnet.PriSub.id]
  //   security_group_ids = [aws_security_group.allow_tls.id]
  // }

  // environment {
  //   variables = {
  //     foo = "bar"
  //   }
  // }
}


resource "aws_s3_bucket" "rahulinux1" {
  bucket = "rahulinux1"
}

resource "aws_lambda_permission" "allow_bucket" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.test_lambda.arn
    principal = "s3.amazonaws.com"
    source_arn = aws_s3_bucket.rahulinux1.arn
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.rahulinux1.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    // filter_prefix       = "AWSLogs/"
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

