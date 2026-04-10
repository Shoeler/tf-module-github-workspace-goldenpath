# Unit tests for the goldenpath module.
#
# All providers are mocked so no real GitHub or HCP Terraform credentials are
# required.  Run with:
#
#   terraform test
#
# Requires Terraform >= 1.7 (mock_provider support).

mock_provider "github" {}
mock_provider "tfe" {}

# ---------------------------------------------------------------------------
# Shared variable defaults – every run block can override individual values.
# ---------------------------------------------------------------------------

variables {
  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"
  oauth_token_id   = "ot-mocktokenid000000"
}

# ---------------------------------------------------------------------------
# GitHub repository
# ---------------------------------------------------------------------------

run "repo_name_is_team_hyphen_project" {
  command = plan

  assert {
    condition     = github_repository.this.name == "platform-payments-api"
    error_message = "Repository name must be '{team}-{project}', got: ${github_repository.this.name}"
  }
}

run "repo_auto_init_is_enabled" {
  command = plan

  assert {
    condition     = github_repository.this.auto_init == true
    error_message = "auto_init must be true so the default branch exists before branch-protection is applied."
  }
}

run "repo_hygiene_defaults" {
  command = plan

  assert {
    condition     = github_repository.this.has_issues == true
    error_message = "has_issues should default to true."
  }

  assert {
    condition     = github_repository.this.has_wiki == false
    error_message = "has_wiki should default to false."
  }

  assert {
    condition     = github_repository.this.has_projects == false
    error_message = "has_projects should default to false."
  }

  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "delete_branch_on_merge should default to true."
  }
}

run "repo_visibility_defaults_to_private" {
  command = plan

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Default visibility should be 'private'."
  }
}

run "repo_visibility_can_be_overridden" {
  command = plan

  variables {
    repo_visibility = "public"
  }

  assert {
    condition     = github_repository.this.visibility == "public"
    error_message = "repo_visibility override to 'public' was not applied."
  }
}

run "repo_description_falls_back_to_team_project" {
  command = plan

  assert {
    condition     = github_repository.this.description == "platform / payments-api"
    error_message = "Default description should be '{team} / {project}', got: ${github_repository.this.description}"
  }
}

run "repo_description_uses_custom_value" {
  command = plan

  variables {
    repo_description = "The payments API service"
  }

  assert {
    condition     = github_repository.this.description == "The payments API service"
    error_message = "Custom repo_description was not applied."
  }
}

# ---------------------------------------------------------------------------
# Long-lived branches
# ---------------------------------------------------------------------------

run "dev_branch_is_sourced_from_main" {
  command = plan

  assert {
    condition     = github_branch.dev.branch == "dev"
    error_message = "dev branch name must be 'dev'."
  }

  assert {
    condition     = github_branch.dev.source_branch == "main"
    error_message = "dev branch must be sourced from 'main'."
  }
}

# ---------------------------------------------------------------------------
# Branch protection – main
# ---------------------------------------------------------------------------

run "branch_protection_main_pattern" {
  command = plan

  assert {
    condition     = github_branch_protection.main.pattern == "main"
    error_message = "main branch protection pattern must be 'main'."
  }
}

run "branch_protection_main_requires_pr" {
  command = plan

  assert {
    condition     = github_branch_protection.main.required_pull_request_reviews[0].required_approving_review_count == 1
    error_message = "main branch protection must require at least 1 approving review."
  }

  assert {
    condition     = github_branch_protection.main.required_pull_request_reviews[0].dismiss_stale_reviews == true
    error_message = "main branch protection must dismiss stale reviews."
  }
}

run "branch_protection_main_blocks_force_push_and_deletion" {
  command = plan

  assert {
    condition     = github_branch_protection.main.allows_force_pushes == false
    error_message = "main branch protection must block force pushes."
  }

  assert {
    condition     = github_branch_protection.main.allows_deletions == false
    error_message = "main branch protection must block branch deletion."
  }
}

# ---------------------------------------------------------------------------
# Branch protection – dev
# ---------------------------------------------------------------------------

run "branch_protection_dev_pattern" {
  command = plan

  assert {
    condition     = github_branch_protection.dev.pattern == "dev"
    error_message = "dev branch protection pattern must be 'dev'."
  }
}

run "branch_protection_dev_requires_pr" {
  command = plan

  assert {
    condition     = github_branch_protection.dev.required_pull_request_reviews[0].required_approving_review_count == 1
    error_message = "dev branch protection must require at least 1 approving review."
  }

  assert {
    condition     = github_branch_protection.dev.required_pull_request_reviews[0].dismiss_stale_reviews == true
    error_message = "dev branch protection must dismiss stale reviews."
  }
}

run "branch_protection_dev_blocks_force_push_and_deletion" {
  command = plan

  assert {
    condition     = github_branch_protection.dev.allows_force_pushes == false
    error_message = "dev branch protection must block force pushes."
  }

  assert {
    condition     = github_branch_protection.dev.allows_deletions == false
    error_message = "dev branch protection must block branch deletion."
  }
}

# ---------------------------------------------------------------------------
# HCP Terraform workspace names
# ---------------------------------------------------------------------------

run "workspace_names_include_team_project_and_env" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.name == "platform-payments-api-dev"
    error_message = "dev workspace name must be '{team}-{project}-dev', got: ${tfe_workspace.dev.name}"
  }

  assert {
    condition     = tfe_workspace.main.name == "platform-payments-api-main"
    error_message = "main workspace name must be '{team}-{project}-main', got: ${tfe_workspace.main.name}"
  }
}

run "workspaces_belong_to_correct_organization" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.organization == "acme-hcp"
    error_message = "dev workspace organization mismatch."
  }

  assert {
    condition     = tfe_workspace.main.organization == "acme-hcp"
    error_message = "main workspace organization mismatch."
  }
}

# ---------------------------------------------------------------------------
# HCP Terraform workspace VCS connections
# ---------------------------------------------------------------------------

run "workspace_vcs_dev_targets_dev_branch" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].branch == "dev"
    error_message = "dev workspace must be connected to the 'dev' branch."
  }
}

run "workspace_vcs_main_targets_main_branch" {
  command = plan

  assert {
    condition     = tfe_workspace.main.vcs_repo[0].branch == "main"
    error_message = "main workspace must be connected to the 'main' branch."
  }
}

run "workspace_vcs_identifier_points_to_correct_repo" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].identifier == "acme-corp/platform-payments-api"
    error_message = "dev workspace VCS identifier must be '{github_org}/{team}-{project}'."
  }

  assert {
    condition     = tfe_workspace.main.vcs_repo[0].identifier == "acme-corp/platform-payments-api"
    error_message = "main workspace VCS identifier must be '{github_org}/{team}-{project}'."
  }
}

# ---------------------------------------------------------------------------
# HCP Terraform workspace tags
# ---------------------------------------------------------------------------

run "workspace_tags_include_team_and_project" {
  command = plan

  assert {
    condition     = contains(tfe_workspace.dev.tag_names, "team:platform")
    error_message = "dev workspace tags must include 'team:{team}'."
  }

  assert {
    condition     = contains(tfe_workspace.dev.tag_names, "project:payments-api")
    error_message = "dev workspace tags must include 'project:{project}'."
  }

  assert {
    condition     = contains(tfe_workspace.main.tag_names, "team:platform")
    error_message = "main workspace tags must include 'team:{team}'."
  }

  assert {
    condition     = contains(tfe_workspace.main.tag_names, "project:payments-api")
    error_message = "main workspace tags must include 'project:{project}'."
  }
}

# ---------------------------------------------------------------------------
# auto_apply behaviour
# ---------------------------------------------------------------------------

run "auto_apply_defaults_to_false" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.auto_apply == false
    error_message = "dev workspace auto_apply must default to false."
  }

  assert {
    condition     = tfe_workspace.main.auto_apply == false
    error_message = "main workspace auto_apply must default to false."
  }
}

run "auto_apply_can_be_enabled" {
  command = plan

  variables {
    auto_apply = true
  }

  assert {
    condition     = tfe_workspace.dev.auto_apply == true
    error_message = "dev workspace auto_apply should be true when overridden."
  }

  assert {
    condition     = tfe_workspace.main.auto_apply == true
    error_message = "main workspace auto_apply should be true when overridden."
  }
}

# ---------------------------------------------------------------------------
# working_directory propagation
# ---------------------------------------------------------------------------

run "working_directory_defaults_to_root" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.working_directory == "/"
    error_message = "dev workspace working_directory must default to '/'."
  }

  assert {
    condition     = tfe_workspace.main.working_directory == "/"
    error_message = "main workspace working_directory must default to '/'."
  }
}

run "working_directory_can_be_overridden" {
  command = plan

  variables {
    terraform_working_directory = "infra/terraform"
  }

  assert {
    condition     = tfe_workspace.dev.working_directory == "infra/terraform"
    error_message = "dev workspace working_directory override was not applied."
  }

  assert {
    condition     = tfe_workspace.main.working_directory == "infra/terraform"
    error_message = "main workspace working_directory override was not applied."
  }
}
