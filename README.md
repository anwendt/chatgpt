# chatgpt

## k8s_sops.sh

This script encrypts or decrypts files using `sops` and `age`. It reads the Age private key from the Kubernetes secret `helm-secrets-private-keys` in the `argocd` namespace.

### Usage

```bash
./k8s_sops.sh [-d|-e] <source_file> <target_file>
```

- `-e` encrypts the source file to the target file
- `-d` decrypts the source file to the target file

The script fails with an error if required commands are not available, the namespace or secret is missing, or the source file does not exist.
