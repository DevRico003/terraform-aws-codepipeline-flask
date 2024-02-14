variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "DevRico003"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "terraform-aws-codepipeline-flask"
}

variable "github_branch" {
  description = "GitHub repository branch"
  type        = string
  default     = "main"
}

variable "github_arn" {
  description = "GitHub repository ARN"
  type        = string
}