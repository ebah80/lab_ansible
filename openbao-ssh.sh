#!/usr/bin/env bash
set -euo pipefail

# Controllo presenza variabili necessarie
if [ -z "${BAO_ADDR:-}" ] || [ -z "${BAO_ROLE_ID:-}" ] || [ -z "${BAO_SECRET_ID:-}" ]; then
  echo "ERROR: Variabili BAO_ADDR, BAO_ROLE_ID o BAO_SECRET_ID non definite." >&2
  exit 1
fi

# 1. Directory temporanea univoca (isolamento totale per la concorrenza di Ansible)
CERT_DIR=$(mktemp -d /tmp/bao_ssh_XXXXXX)

# 2. Trap pulizia: elimina la chiave a fine connessione SSH
trap 'rm -rf "$CERT_DIR"' EXIT INT TERM

# 3. Autenticazione AppRole via API
LOGIN_RESP=$(curl -s -k --request POST \
  --data "{\"role_id\": \"$BAO_ROLE_ID\", \"secret_id\": \"$BAO_SECRET_ID\"}" \
  "$BAO_ADDR/v1/auth/approle/login" < /dev/null)

BAO_TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('auth', {}).get('client_token', ''))" 2>/dev/null)

if [ -z "$BAO_TOKEN" ]; then
  echo "ERROR: Autenticazione OpenBao fallita. Risposta: $LOGIN_RESP" >&2
  exit 1
fi

# 4. Generazione coppia di chiavi temporanea unica per questa esecuzione
ssh-keygen -t ed25519 -N "" -f "$CERT_DIR/id_ed25519" -q < /dev/null

PUB_KEY=$(cat "$CERT_DIR/id_ed25519.pub")

# 5. Firma della chiave tramite OpenBao API
SIGN_RESP=$(curl -s -k --header "X-Vault-Token: $BAO_TOKEN" \
  --request POST \
  --data "{\"valid_principals\": \"ansible\", \"public_key\": \"$PUB_KEY\"}" \
  "$BAO_ADDR/v1/ssh-client-signer/sign/ansible-role" < /dev/null)

echo "$SIGN_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('data', {}).get('signed_key', ''))" > "$CERT_DIR/id_ed25519-cert.pub" 2>/dev/null

if [ ! -s "$CERT_DIR/id_ed25519-cert.pub" ]; then
  echo "ERROR: Impossibile firmare il certificato SSH. Risposta: $SIGN_RESP" >&2
  exit 1
fi

# 6. Esecuzione SSH (senza exec per permettere al TRAP di eliminare i file al termine)
ssh -o StrictHostKeyChecking=no \
    -o CertificateFile="$CERT_DIR/id_ed25519-cert.pub" \
    -i "$CERT_DIR/id_ed25519" \
    "$@"
