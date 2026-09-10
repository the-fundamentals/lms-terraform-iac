#!/bin/bash

set -euxo pipefail

dnf update -y

dnf install -y postgresql18-server postgresql18

