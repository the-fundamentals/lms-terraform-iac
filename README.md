# LMS Terraform IAC

Infrastructure for the LMS stack (AWS). Sibling repos: `lms-core-api`, `lms-web-management`.

## Tooling (mise)

From this directory:

```bash
mise trust
mise install
```

## Cloud Agent checks

This repo’s `.cursor/environment.json` runs the same gates on builds (no AWS credentials):

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

The `lms-core-api` LMS environment also runs these checks when this repo is checked out as a sibling dependency.
