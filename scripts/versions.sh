#!/usr/bin/env bash
echo "terraform: $(terraform version | head -1)"
echo "ansible:   $(ansible --version | head -1)"
echo "kubectl:   $(kubectl version --client -o json | jq -r .clientVersion.gitVersion)"
echo "trivy(local): $(trivy --version | head -1)"
echo "cosign:    $(cosign version 2>/dev/null | grep GitVersion)"
echo "helm:      $(helm version --short)"
