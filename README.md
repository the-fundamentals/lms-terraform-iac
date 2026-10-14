# LMS Terraform IAC

Infrastructure for the LMS stack (AWS). Sibling repos: `lms-core-api`, `lms-web-management`.

## Tooling (mise)

From this directory:

```bash
mise trust
mise install
```

## Cloud Agent checks

The `lms-core-api` environment install script validates this repo (no AWS credentials):

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

Build pods check out `random/hotfix` here when `mise.toml` is not on the cloned default branch.
