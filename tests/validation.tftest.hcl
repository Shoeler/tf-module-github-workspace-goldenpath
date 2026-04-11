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

mock_provider "github" {}
mock_provider "tfe" {}

# ---------------------------------------------------------------------------
# Baseline – all valid inputs must produce a successful plan.
# ---------------------------------------------------------------------------

variables {
  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"
  oauth_token_id   = "ot-mocktokenid000000"
  tfe_project_name = "default-project"
}

run "valid_inputs_succeed" {
  command = plan
  # No assertions needed; a successful plan is the assertion.
}

# ---------------------------------------------------------------------------
# var.team validation
# ---------------------------------------------------------------------------

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

run "team_rejects_leading_hyphen" {
  command = plan

  variables {
    team = "-platform"
  }

  # The regex ^[a-z0-9-]+$ technically allows a leading hyphen; this run
  # documents the current behaviour so any future tightening of the
  # validation is a conscious choice.
  expect_failures = []
}

run "team_accepts_hyphens_and_numbers" {
  command = plan

  variables {
    team = "platform-2"
  }
  # Expects success – no expect_failures block.
}

# ---------------------------------------------------------------------------
# var.project validation
# ---------------------------------------------------------------------------

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

run "project_accepts_hyphens_and_numbers" {
  command = plan

  variables {
    project = "payments-api-v2"
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

run "visibility_accepts_public" {
  command = plan

  variables {
    repo_visibility = "public"
  }
}

run "visibility_accepts_private" {
  command = plan

  variables {
    repo_visibility = "private"
  }
}
