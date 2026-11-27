locals {
  app_v1_dir = "${path.module}/../src/app-v1"
  app_v1_zip = abspath("${path.module}/.terraform/node-app-v1.zip")

  app_v2_dir = "${path.module}/../src/app-v2"
  app_v2_zip = abspath("${path.module}/.terraform/node-app-v2.zip")
}

resource "terraform_data" "app_v1_zip" {
  triggers_replace = [
    fileset(local.app_v1_dir, "**/*")
  ]

  provisioner "local-exec" {
    command = "mkdir -p \"${path.module}/.terraform\" && rm -f \"${local.app_v1_zip}\" && (cd \"${local.app_v1_dir}\" && zip -rq \"${local.app_v1_zip}\" . -x 'node_modules/*' '.git/*' '.env*')"
  }
}

resource "terraform_data" "app_v2_zip" {
  triggers_replace = [
    fileset(local.app_v1_dir, "**/*")
  ]

  provisioner "local-exec" {
    command = "mkdir -p \"${path.module}/.terraform\" && rm -f \"${local.app_v2_zip}\" && (cd \"${local.app_v2_dir}\" && zip -rq \"${local.app_v2_zip}\" . -x 'node_modules/*' '.git/*' '.env*')"
  }
}

resource "aws_s3_bucket" "eb_artifacts" {
  bucket = "elasticbeanstalk-artifacts-uniq"
}

resource "aws_s3_object" "app_v1" {
  bucket     = aws_s3_bucket.eb_artifacts.id
  key        = "app-v1.zip"
  source     = local.app_v1_zip
  depends_on = [terraform_data.app_v1_zip]
}

resource "aws_s3_object" "app_v2" {
  bucket     = aws_s3_bucket.eb_artifacts.id
  key        = "app-v2.zip"
  source     = local.app_v2_zip
  depends_on = [terraform_data.app_v2_zip]
}
