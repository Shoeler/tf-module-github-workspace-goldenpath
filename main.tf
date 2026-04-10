locals {
  repo_name      = "${var.team}-${var.project}"
  branches       = ["dev", "main"]
  workspace_tags = ["team:${var.team}", "project:${var.project}"]
}

# ---------------------------------------------------------------------------
# GitHub Repository
# ---------------------------------------------------------------------------

resource "github_repository" "this" {
  name        = local.repo_name
  description = var.repo_description != "" ? var.repo_description : "${var.team} / ${var.project}"
  visibility  = var.repo_visibility

  # Initialise with a README so the default branch exists immediately,
  # allowing branch and branch-protection resources to apply without error.
  auto_init = true

  # Sensible repository hygiene defaults.
  has_issues      = true
  has_wiki        = false
  has_projects    = false
  delete_branch_on_merge = true
}

# ---------------------------------------------------------------------------
# Long-lived branches
# ---------------------------------------------------------------------------

# `main` is created automatically by auto_init, so we only need to create `dev`.
resource "github_branch" "dev" {
  repository    = github_repository.this.name
  branch        = "dev"
  source_branch = "main"

  depends_on = [github_repository.this]
}

# ---------------------------------------------------------------------------
# Branch protection – require pull requests before merging
# ---------------------------------------------------------------------------

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  # Block direct pushes; all changes must come through a PR.
  allows_deletions    = false
  allows_force_pushes = false

  depends_on = [github_repository.this]
}

resource "github_branch_protection" "dev" {
  repository_id = github_repository.this.node_id
  pattern       = "dev"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
  }

  allows_deletions    = false
  allows_force_pushes = false

  depends_on = [github_branch.dev]
}

# ---------------------------------------------------------------------------
# HCP Terraform workspaces
# ---------------------------------------------------------------------------

resource "tfe_workspace" "dev" {
  name         = "${local.repo_name}-dev"
  organization = var.tfe_organization
  auto_apply   = var.auto_apply
  tag_names    = local.workspace_tags

  vcs_repo {
    identifier     = "${var.github_org}/${local.repo_name}"
    oauth_token_id = var.oauth_token_id
    branch         = "dev"
  }

  working_directory = var.terraform_working_directory

  depends_on = [github_branch.dev]
}

resource "tfe_workspace" "main" {
  name         = "${local.repo_name}-main"
  organization = var.tfe_organization
  auto_apply   = var.auto_apply
  tag_names    = local.workspace_tags

  vcs_repo {
    identifier     = "${var.github_org}/${local.repo_name}"
    oauth_token_id = var.oauth_token_id
    branch         = "main"
  }

  working_directory = var.terraform_working_directory

  depends_on = [github_repository.this]
}
