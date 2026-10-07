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
  has_issues             = true
  has_wiki               = false
  has_projects           = false
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
# Branch rulesets – require pull requests before merging (GitHub Free compatible)
# ---------------------------------------------------------------------------

resource "github_repository_ruleset" "main" {
  repository  = github_repository.this.name
  name        = "main-protection"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
    }
  }

  depends_on = [github_repository.this]
}

resource "github_repository_ruleset" "dev" {
  repository  = github_repository.this.name
  name        = "dev-protection"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/dev"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
    }
  }

  depends_on = [github_branch.dev]
}

# ---------------------------------------------------------------------------
# HCP Terraform workspaces
# ---------------------------------------------------------------------------

data "tfe_project" "this" {
  name         = var.tfe_project_name
  organization = var.tfe_organization
}

resource "tfe_workspace" "dev" {
  name         = "${local.repo_name}-dev"
  organization = var.tfe_organization
  project_id   = data.tfe_project.this.id
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
  project_id   = data.tfe_project.this.id
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
