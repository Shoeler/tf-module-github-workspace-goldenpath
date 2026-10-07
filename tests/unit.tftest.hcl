# Unit tests for the goldenpath module.
#
# All providers are mocked so no real GitHub or HCP Terraform credentials are
# required.  Run with:
#
#   terraform test
#
# Requires Terraform >= 1.7 (mock_provider support).
#
# Layout: one run block per resource (or per set of overrides) with every
# related assertion inside it.  Terraform evaluates all assertions in a run
# and reports each failure, so grouping loses no diagnostic detail.  Separate
# run blocks exist only where the input variables differ.

mock_provider "github" {}
mock_provider "tfe" {}

# Give the project data source a known ID so workspace wiring can be asserted.
override_data {
  target = data.tfe_project.this
  values = {
    id = "prj-test0000000001"
  }
}

# ---------------------------------------------------------------------------
# Shared variable defaults – every run block can override individual values.
# ---------------------------------------------------------------------------

variables {
  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"
  oauth_token_id   = "ot-mocktokenid000000"
  tfe_project_name = "default-project"
}

# ---------------------------------------------------------------------------
# GitHub repository
# ---------------------------------------------------------------------------

run "repository_defaults" {
  command = plan

  assert {
    condition     = github_repository.this.name == "platform-payments-api"
    error_message = "Repository name must be '{team}-{project}', got: ${github_repository.this.name}"
  }

  assert {
    condition     = github_repository.this.description == "platform / payments-api"
    error_message = "Default description should be '{team} / {project}', got: ${github_repository.this.description}"
  }

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Default visibility should be 'private'."
  }

  # auto_init creates the default branch; github_branch.dev and both rulesets
  # fail at apply time if it is ever turned off.
  assert {
    condition     = github_repository.this.auto_init == true
    error_message = "auto_init must be true so the default branch exists before rulesets are applied."
  }

  assert {
    condition     = github_repository.this.has_issues == true && github_repository.this.has_wiki == false && github_repository.this.has_projects == false
    error_message = "Repository hygiene defaults changed: expected issues on, wiki off, projects off."
  }

  # delete_branch_on_merge would try to delete `dev` after a dev -> main PR;
  # the dev ruleset's deletion rule is what stops that.
  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "delete_branch_on_merge should default to true."
  }
}

run "repository_overrides" {
  command = plan

  variables {
    repo_visibility  = "public"
    repo_description = "The payments API service"
  }

  assert {
    condition     = github_repository.this.visibility == "public"
    error_message = "repo_visibility override to 'public' was not applied."
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
    condition     = github_branch.dev.repository == github_repository.this.name
    error_message = "dev branch must be created in the module's repository."
  }

  assert {
    condition     = github_branch.dev.branch == "dev" && github_branch.dev.source_branch == "main"
    error_message = "dev branch must be named 'dev' and sourced from 'main'."
  }
}

# ---------------------------------------------------------------------------
# Branch rulesets
# ---------------------------------------------------------------------------

run "ruleset_main_requires_pr_and_blocks_deletion_and_force_push" {
  command = plan

  assert {
    condition     = github_repository_ruleset.main.repository == github_repository.this.name
    error_message = "main ruleset must apply to the module's repository."
  }

  assert {
    condition     = github_repository_ruleset.main.target == "branch" && github_repository_ruleset.main.enforcement == "active"
    error_message = "main ruleset must be an active branch ruleset."
  }

  assert {
    condition     = github_repository_ruleset.main.conditions[0].ref_name[0].include == tolist(["refs/heads/main"])
    error_message = "main ruleset must include only 'refs/heads/main'."
  }

  assert {
    condition     = github_repository_ruleset.main.rules[0].pull_request[0].required_approving_review_count == 1
    error_message = "main ruleset must require at least 1 approving review."
  }

  assert {
    condition     = github_repository_ruleset.main.rules[0].pull_request[0].dismiss_stale_reviews_on_push == true
    error_message = "main ruleset must dismiss stale reviews on push."
  }

  assert {
    condition     = github_repository_ruleset.main.rules[0].deletion == true
    error_message = "main ruleset must block branch deletion."
  }

  assert {
    condition     = github_repository_ruleset.main.rules[0].non_fast_forward == true
    error_message = "main ruleset must block force pushes (non_fast_forward)."
  }
}

run "ruleset_dev_requires_pr_and_blocks_deletion_and_force_push" {
  command = plan

  assert {
    condition     = github_repository_ruleset.dev.repository == github_repository.this.name
    error_message = "dev ruleset must apply to the module's repository."
  }

  assert {
    condition     = github_repository_ruleset.dev.target == "branch" && github_repository_ruleset.dev.enforcement == "active"
    error_message = "dev ruleset must be an active branch ruleset."
  }

  assert {
    condition     = github_repository_ruleset.dev.conditions[0].ref_name[0].include == tolist(["refs/heads/dev"])
    error_message = "dev ruleset must include only 'refs/heads/dev'."
  }

  assert {
    condition     = github_repository_ruleset.dev.rules[0].pull_request[0].required_approving_review_count == 1
    error_message = "dev ruleset must require at least 1 approving review."
  }

  assert {
    condition     = github_repository_ruleset.dev.rules[0].pull_request[0].dismiss_stale_reviews_on_push == true
    error_message = "dev ruleset must dismiss stale reviews on push."
  }

  assert {
    condition     = github_repository_ruleset.dev.rules[0].deletion == true
    error_message = "dev ruleset must block branch deletion."
  }

  assert {
    condition     = github_repository_ruleset.dev.rules[0].non_fast_forward == true
    error_message = "dev ruleset must block force pushes (non_fast_forward)."
  }
}

# ---------------------------------------------------------------------------
# HCP Terraform workspaces
# ---------------------------------------------------------------------------

run "workspaces_defaults" {
  command = plan

  assert {
    condition     = tfe_workspace.dev.name == "platform-payments-api-dev" && tfe_workspace.main.name == "platform-payments-api-main"
    error_message = "Workspace names must be '{team}-{project}-{env}', got: ${tfe_workspace.dev.name}, ${tfe_workspace.main.name}"
  }

  assert {
    condition     = tfe_workspace.dev.organization == "acme-hcp" && tfe_workspace.main.organization == "acme-hcp"
    error_message = "Both workspaces must be created in var.tfe_organization."
  }

  assert {
    condition     = data.tfe_project.this.name == "default-project" && data.tfe_project.this.organization == "acme-hcp"
    error_message = "tfe_project data source must look up var.tfe_project_name in var.tfe_organization."
  }

  assert {
    condition     = tfe_workspace.dev.project_id == "prj-test0000000001" && tfe_workspace.main.project_id == "prj-test0000000001"
    error_message = "Both workspaces must be placed in the project resolved by data.tfe_project.this."
  }

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].identifier == "acme-corp/platform-payments-api" && tfe_workspace.main.vcs_repo[0].identifier == "acme-corp/platform-payments-api"
    error_message = "Workspace VCS identifier must be '{github_org}/{team}-{project}'."
  }

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].branch == "dev" && tfe_workspace.main.vcs_repo[0].branch == "main"
    error_message = "dev workspace must track 'dev' and main workspace must track 'main'."
  }

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].oauth_token_id == "ot-mocktokenid000000" && tfe_workspace.main.vcs_repo[0].oauth_token_id == "ot-mocktokenid000000"
    error_message = "Both workspaces must use var.oauth_token_id for the VCS connection."
  }

  assert {
    condition     = tfe_workspace.dev.tag_names == toset(["team:platform", "project:payments-api"]) && tfe_workspace.main.tag_names == toset(["team:platform", "project:payments-api"])
    error_message = "Workspace tags must be exactly {team:{team}, project:{project}}."
  }

  assert {
    condition     = tfe_workspace.dev.auto_apply == false && tfe_workspace.main.auto_apply == false
    error_message = "auto_apply must default to false on both workspaces."
  }

  assert {
    condition     = tfe_workspace.dev.working_directory == "/" && tfe_workspace.main.working_directory == "/"
    error_message = "working_directory must default to '/' on both workspaces."
  }
}

run "workspaces_overrides" {
  command = plan

  variables {
    github_org                  = "other-org"
    tfe_project_name            = "my-custom-project"
    auto_apply                  = true
    terraform_working_directory = "infra/terraform"
  }

  assert {
    condition     = tfe_workspace.dev.vcs_repo[0].identifier == "other-org/platform-payments-api" && tfe_workspace.main.vcs_repo[0].identifier == "other-org/platform-payments-api"
    error_message = "github_org override must flow into the VCS identifier of both workspaces."
  }

  assert {
    condition     = data.tfe_project.this.name == "my-custom-project"
    error_message = "tfe_project_name override must flow into the project lookup."
  }

  assert {
    condition     = tfe_workspace.dev.auto_apply == true && tfe_workspace.main.auto_apply == true
    error_message = "auto_apply override must apply to both workspaces."
  }

  assert {
    condition     = tfe_workspace.dev.working_directory == "infra/terraform" && tfe_workspace.main.working_directory == "infra/terraform"
    error_message = "working_directory override must apply to both workspaces."
  }
}

# ---------------------------------------------------------------------------
# Outputs – apply against mocks so computed attributes (IDs, URLs) get values.
# ---------------------------------------------------------------------------

run "outputs_point_at_the_right_resources" {
  command = apply

  assert {
    condition     = output.repo_name == github_repository.this.name
    error_message = "repo_name output must expose the repository name."
  }

  assert {
    condition     = output.repo_html_url == github_repository.this.html_url && output.repo_ssh_clone_url == github_repository.this.ssh_clone_url
    error_message = "Repository URL outputs must come from github_repository.this."
  }

  assert {
    condition     = output.workspace_dev_id == tfe_workspace.dev.id && output.workspace_main_id == tfe_workspace.main.id
    error_message = "Workspace ID outputs must map dev -> dev and main -> main."
  }

  assert {
    condition     = output.workspace_dev_url == tfe_workspace.dev.html_url && output.workspace_main_url == tfe_workspace.main.html_url
    error_message = "Workspace URL outputs must map dev -> dev and main -> main."
  }
}
