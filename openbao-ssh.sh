#!/bin/bash
# file: openbao-ssh.sh
set -e

# Crea una directory temporanea univoca per questo task
CERT_DIR="/tmp/bao_cert_$$"
mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"

# 1. Login a OpenBao e recupero Token (estrae il JSON via Python)
BAO_TOKEN=$(curl -s -k --request POST \
  --data "{\"role_id\": \"$BAO_ROLE_ID\", \"secret_id\": \"$BAO_SECRET_ID\"}" \
  "$BAO_ADDR/v1/auth/approle/login" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['auth']['client_token'])")

# 2. Generazione chiave locale
ssh-keygen -t ed25519 -N "" -f "$CERT_DIR/id_ed25519" -q

# 3. Richiesta firma certificato
PUB_KEY=$(cat "$CERT_DIR/id_ed25519.pub")
curl -s -k --header "X-Vault-Token: $BAO_TOKEN" \
  --request POST \
  --data "{\"valid_principals\": \"ansible\", \"public_key\": \"$PUB_KEY\"}" \
  "$BAO_ADDR/v1/ssh-client-signer/sign/ansible-role" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['data']['signed_key'])" > "$CERT_DIR/id_ed25519-cert.pub"

# 4. Esecuzione del comando SSH originale richiesto da Ansible
ssh -o StrictHostKeyChecking=no -i "$CERT_DIR/id_ed25519" -i "$CERT_DIR/id_ed25519-cert.pub" "$@"
EXIT_CODE=$?

# 5. Pulizia delle chiavi al termine
rm -rf "$CERT_DIR"
exit $EXIT_CODE
