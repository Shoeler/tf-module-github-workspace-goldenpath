# Variable validation tests for the goldenpath module.
#
# Each run block verifies that an invalid input is rejected by the
# variable's validation block, or that a valid input is accepted.
#
# Run with:
#
#   terraform test
#
# Requires Terraform >= 1.7 (mock_provider support).
#
# Each rejection needs its own run block because expect_failures applies to a
# whole run.  Accepted-value runs are kept to one per variable; the unit suite
# already exercises the defaults.

mock_provider "github" {}
mock_provider "tfe" {}

variables {
  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"
  oauth_token_id   = "ot-mocktokenid000000"
  tfe_project_name = "default-project"
}

# ---------------------------------------------------------------------------
# var.team validation
# ---------------------------------------------------------------------------

run "team_rejects_empty_string" {
  command = plan

  variables {
    team = ""
  }

  expect_failures = [var.team]
}

run "team_rejects_uppercase_letters" {
  command = plan

  variables {
    team = "Platform"
  }

  expect_failures = [var.team]
}

run "team_rejects_spaces" {
  command = plan

  variables {
    team = "my team"
  }

  expect_failures = [var.team]
}

run "team_rejects_underscores" {
  command = plan

  variables {
    team = "my_team"
  }

  expect_failures = [var.team]
}

run "team_accepts_hyphens_and_digits" {
  command = plan

  variables {
    team = "platform-2"
  }

  assert {
    condition     = github_repository.this.name == "platform-2-payments-api"
    error_message = "A valid team containing hyphens and digits must flow into the repository name."
  }
}

# The regex ^[a-z0-9-]+$ allows a leading hyphen.  This run documents that
# so any future tightening of the validation is a conscious choice.
run "team_currently_accepts_leading_hyphen" {
  command = plan

  variables {
    team = "-platform"
  }

  assert {
    condition     = github_repository.this.name == "-platform-payments-api"
    error_message = "Leading hyphen in team is currently accepted; update this run if validation is tightened."
  }
}

# ---------------------------------------------------------------------------
# var.project validation
# ---------------------------------------------------------------------------

run "project_rejects_empty_string" {
  command = plan

  variables {
    project = ""
  }

  expect_failures = [var.project]
}

run "project_rejects_uppercase_letters" {
  command = plan

  variables {
    project = "PaymentsAPI"
  }

  expect_failures = [var.project]
}

run "project_rejects_spaces" {
  command = plan

  variables {
    project = "payments api"
  }

  expect_failures = [var.project]
}

run "project_rejects_underscores" {
  command = plan

  variables {
    project = "payments_api"
  }

  expect_failures = [var.project]
}

run "project_accepts_hyphens_and_digits" {
  command = plan

  variables {
    project = "payments-api-v2"
  }

  assert {
    condition     = tfe_workspace.main.name == "platform-payments-api-v2-main"
    error_message = "A valid project containing hyphens and digits must flow into the workspace name."
  }
}

# ---------------------------------------------------------------------------
# var.repo_visibility validation
# ---------------------------------------------------------------------------

run "visibility_rejects_internal" {
  command = plan

  variables {
    repo_visibility = "internal"
  }

  expect_failures = [var.repo_visibility]
}

run "visibility_rejects_arbitrary_string" {
  command = plan

  variables {
    repo_visibility = "secret"
  }

  expect_failures = [var.repo_visibility]
}
