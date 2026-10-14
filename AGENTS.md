# LMS Terraform IAC

AWS infrastructure for the LMS stack. Sibling application repos: `lms-core-api`, `lms-web-management`.

## Tooling (mise)

```bash
mise trust
mise install
```

Pinned in `mise.toml`: Terraform, Python (for pipx), optional `terraform-local`.

## Cloud Agent environment

Committed `.cursor/environment.json` runs `.cursor/cloud-agent-install.sh` on environment builds:

- Install and trust mise
- `terraform fmt -check -recursive`
- `terraform init -backend=false -input=false`
- `terraform validate`

No AWS credentials are required for these checks. Do not run `terraform apply` or mutate live infrastructure unless the user explicitly asks.

The combined LMS environment in `lms-core-api` also validates this repo when `lms-terraform-iac` is listed under `repositoryDependencies`.

## Local commands

```bash
terraform fmt -recursive
terraform init -backend=false -input=false
terraform validate
```

Use real AWS credentials and configured remote state only for plan/apply workflows outside the default agent bootstrap.
