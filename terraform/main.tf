provider "aws" {
  region = var.aws_region
}

resource "aws_codestarconnections_connection" "github" {
  name          = "my-github-connection"
  provider_type = "GitHub"
}

resource "random_pet" "bucket_suffix" {
  length = 2
  prefix = "techstarter"
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = "techstarter-artifact-store-${random_pet.bucket_suffix.id}"
}

resource "aws_iam_role" "pipeline" {
  name = "techstarter-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_iam_role" "codebuild" {
  name = "techstarter-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "codebuild.amazonaws.com" }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "techstarter-codebuild-policy"
  description = "Policy for CodeBuild to access resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifact_store.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_codebuild_project" "build_project" {
  name          = "techstarter-build-project"
  description   = "Build project for Techstarter"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 5

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

resource "aws_codebuild_project" "test_project" {
  name          = "techstarter-test-project"
  description   = "Test project for Techstarter"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 5

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "testspec.yml"
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "techstarter-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["sourceOutput"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Prod"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["sourceOutput"]
      output_artifacts = ["buildOutput"]
      version         = "1"
      configuration   = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }

    action {
      name            = "Test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["buildOutput"]
      version         = "1"
      configuration   = {
        ProjectName = aws_codebuild_project.test_project.name
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "Manual_Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }
}