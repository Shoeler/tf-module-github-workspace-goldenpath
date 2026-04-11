# tf-github-workspace-goldenpath

A Terraform module that provisions a complete golden-path project environment from a single `team` + `project` input pair.

One `terraform apply` creates:

- A GitHub repository with two long-lived branches (`main`, `dev`)
- Branch protection on both branches requiring pull-request reviews
- Two HCP Terraform workspaces (`*-main`, `*-dev`) each connected to their matching branch via VCS

---

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │           GitHub Repository          │
                        │         {team}-{project}             │
                        │                                      │
                        │  branch: main  ──► branch protection │
                        │  branch: dev   ──► branch protection │
                        │  (require PR, dismiss stale reviews) │
                        └──────────┬──────────────┬───────────┘
                                   │              │
                      VCS trigger  │              │  VCS trigger
                       (main)      │              │   (dev)
                                   ▼              ▼
                   ┌───────────────────┐  ┌───────────────────┐
                   │   HCP Terraform   │  │   HCP Terraform   │
                   │  {team}-{project} │  │  {team}-{project} │
                   │      -main        │  │       -dev        │
                   └───────────────────┘  └───────────────────┘
```

---

## Prerequisites

### VCS OAuth token

This module requires an OAuth token that HCP Terraform uses to connect workspaces to GitHub. To find or create one:

1. In HCP Terraform, go to **Settings → VCS Providers**
2. If no GitHub connection exists, click **Add VCS Provider** and follow the OAuth flow
3. Once connected, copy the token ID — it begins with `ot-`
4. Store it as a sensitive Terraform variable named `oauth_token_id` (see [Configuring variables in HCP Terraform](#configuring-variables-in-hcp-terraform))

---

## Usage

Sensitive values (`oauth_token_id`, `GITHUB_TOKEN`, `TFE_TOKEN`) are never written in code. They are set directly on the workspace in HCP Terraform — see [Configuring variables in HCP Terraform](#configuring-variables-in-hcp-terraform).

```hcl
module "payments_api" {
  source = "git::https://github.com/your-org/tf-github-workspace-goldenpath.git"

  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"

  # oauth_token_id is set as a sensitive Terraform variable in HCP Terraform,
  # not hardcoded here.
}
```

Access the created resources through outputs:

```hcl
output "repo_url" {
  value = module.payments_api.repo_html_url
}

output "dev_workspace" {
  value = module.payments_api.workspace_dev_url
}
```

### Customising defaults

```hcl
module "payments_api" {
  source = "git::https://github.com/your-org/tf-github-workspace-goldenpath.git"

  team             = "platform"
  project          = "payments-api"
  github_org       = "acme-corp"
  tfe_organization = "acme-hcp"

  # Optional overrides
  repo_description            = "Core payments processing service"
  repo_visibility             = "private"   # default
  terraform_working_directory = "infra/terraform"
  auto_apply                  = false       # default; set true for dev only
}
```

---

## Configuring variables in HCP Terraform

All credentials and sensitive values are configured directly in HCP Terraform — never in source code.

There are two kinds of variables in an HCP Terraform workspace:

- **Terraform Variables** — passed to Terraform as input variables (equivalent to `TF_VAR_*`). Set these for values declared in `variables.tf`.
- **Environment Variables** — set in the shell before Terraform runs. Provider SDKs read credentials from well-known environment variable names automatically.

### Provider credentials (Environment Variables)

Set these on the workspace as **Environment Variables**, marked **Sensitive**.

| Variable | Description | Required scope |
|----------|-------------|----------------|
| `GITHUB_TOKEN` | GitHub personal access token or GitHub App installation token | `repo`, `admin:org` |
| `TFE_TOKEN` | HCP Terraform API token with permission to create workspaces in `tfe_organization` | Manage Workspaces |

To add an environment variable:

1. Open the workspace in HCP Terraform
2. Go to **Variables**
3. Under **Environment Variables**, click **+ Add variable**
4. Enter the name and value, check **Sensitive**, then **Save**

### Terraform input variables

Set these on the workspace as **Terraform Variables**.

| Variable | Sensitive | Recommended location |
|----------|-----------|----------------------|
| `oauth_token_id` | **Yes** | Workspace variable or Variable Set |
| `tfe_project_name` | No | Workspace variable or Variable Set |
| `github_org` | No | Variable Set (same for all workspaces) |
| `tfe_organization` | No | Variable Set (same for all workspaces) |
| `team` | No | Workspace variable |
| `project` | No | Workspace variable |

To add a Terraform variable:

1. Open the workspace in HCP Terraform
2. Go to **Variables**
3. Under **Terraform Variables**, click **+ Add variable**
4. Enter the name (must match the variable name exactly) and value
5. Check **Sensitive** for `oauth_token_id`, then **Save**

> **Note:** Once a variable is marked Sensitive, its value is write-only — it cannot be read back through the UI or API, only overwritten. If a sensitive value needs to be rotated, overwrite it directly on the variable.

### Using Variable Sets for shared values

`github_org`, `tfe_organization`, `GITHUB_TOKEN`, and `TFE_TOKEN` are typically the same across all workspaces in the organization. Use a **Variable Set** to define them once and apply them everywhere rather than duplicating them on each workspace.

1. In HCP Terraform, go to **Settings → Variable Sets**
2. Click **Create variable set**
3. Give it a name (e.g., `platform-defaults`) and optionally a description
4. Add the shared variables, marking credentials as Sensitive
5. Under **Scope**, choose **Apply to all workspaces** or select specific projects
6. Click **Create variable set**

Workspace-level variables take precedence over Variable Set values if both define the same name, which allows per-workspace overrides when needed.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `team` | Team that owns the repository and workspaces. Lowercase alphanumeric and hyphens only. | `string` | — | yes |
| `project` | Project name used as the repository name and workspace prefix. Lowercase alphanumeric and hyphens only. | `string` | — | yes |
| `github_org` | GitHub organization under which the repository will be created. | `string` | — | yes |
| `tfe_organization` | HCP Terraform organization under which workspaces will be created. | `string` | — | yes |
| `oauth_token_id` | HCP Terraform VCS OAuth token ID used to connect workspaces to GitHub. | `string` | — | yes |
| `repo_description` | Optional description for the GitHub repository. Falls back to `{team} / {project}` when empty. | `string` | `""` | no |
| `repo_visibility` | Visibility of the GitHub repository. Must be `public` or `private`. | `string` | `"private"` | no |
| `terraform_working_directory` | Path within the repository where Terraform configuration lives. | `string` | `"/"` | no |
| `auto_apply` | Whether HCP Terraform workspaces auto-apply on successful plans. | `bool` | `false` | no |
| `tfe_project_name` | HCP Terraform project name under which workspaces will be created. | `string` | `"Default Project"` | no |

### Naming constraints

`team` and `project` must match `^[a-z0-9-]+$` (lowercase letters, digits, hyphens). This keeps repository and workspace names consistent across tools and avoids provider-level rejections.

---

## Outputs

| Name | Description |
|------|-------------|
| `repo_name` | Name of the created GitHub repository (`{team}-{project}`). |
| `repo_html_url` | GitHub web URL for the repository. |
| `repo_ssh_clone_url` | SSH clone URL for the repository. |
| `workspace_dev_id` | HCP Terraform workspace ID for the dev environment. |
| `workspace_main_id` | HCP Terraform workspace ID for the main environment. |
| `workspace_dev_url` | HCP Terraform UI URL for the dev workspace. |
| `workspace_main_url` | HCP Terraform UI URL for the main workspace. |

---

## Resources

| Resource | Name pattern | Description |
|----------|-------------|-------------|
| `github_repository` | `{team}-{project}` | Auto-initialised private repository |
| `github_branch` | `dev` | Long-lived dev branch sourced from `main` |
| `github_branch_protection` | `main` | PR required, stale reviews dismissed, force-push blocked |
| `github_branch_protection` | `dev` | PR required, stale reviews dismissed, force-push blocked |
| `tfe_workspace` | `{team}-{project}-main` | VCS-connected to the `main` branch |
| `tfe_workspace` | `{team}-{project}-dev` | VCS-connected to the `dev` branch |

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.6.0` (`>= 1.7.0` to run tests) |
| `integrations/github` provider | `~> 6.0` |
| `hashicorp/tfe` provider | `~> 0.57` |

---

## Testing

Tests use Terraform's native test framework with mocked providers — no real credentials required.

```bash
terraform init
terraform test
```

The test suite is split into two files:

| File | Runs | Covers |
|------|------|--------|
| [`tests/unit.tftest.hcl`](tests/unit.tftest.hcl) | 20 | Resource configuration: naming, branch setup, protection rules, workspace VCS bindings, tags, `auto_apply`, `working_directory` |
| [`tests/validation.tftest.hcl`](tests/validation.tftest.hcl) | 14 | Variable validation: rejects invalid `team`, `project`, and `repo_visibility` values |

---

## Workflow

After `terraform apply`, the typical development loop is:

```
feature branch  ──► PR into dev  ──► merge triggers dev workspace plan/apply
                                                │
                                         PR into main ──► merge triggers main workspace plan/apply
```

Branch protection ensures no direct commits reach either long-lived branch.

---

## License

[MIT](LICENSE)
