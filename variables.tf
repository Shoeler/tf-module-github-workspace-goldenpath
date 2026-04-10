variable "team" {
  description = "Team that owns the repository and workspaces (used in naming and tagging)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.team))
    error_message = "team must be lowercase alphanumeric with hyphens only."
  }
}

variable "project" {
  description = "Project name (used as the GitHub repository name and workspace name prefix)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens only."
  }
}

variable "github_org" {
  description = "GitHub organization under which the repository will be created."
  type        = string
}

variable "tfe_organization" {
  description = "HCP Terraform organization under which workspaces will be created."
  type        = string
}

variable "oauth_token_id" {
  description = "HCP Terraform VCS OAuth token ID used to connect workspaces to GitHub."
  type        = string
  sensitive   = true
}

variable "repo_description" {
  description = "Optional description for the GitHub repository."
  type        = string
  default     = ""
}

variable "repo_visibility" {
  description = "Visibility of the GitHub repository: public or private."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.repo_visibility)
    error_message = "repo_visibility must be either \"public\" or \"private\"."
  }
}

variable "terraform_working_directory" {
  description = "Path within the repository where Terraform configuration lives."
  type        = string
  default     = "/"
}

variable "auto_apply" {
  description = "Whether HCP Terraform workspaces should auto-apply on successful plans."
  type        = bool
  default     = false
}
