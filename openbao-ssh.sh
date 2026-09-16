#!/usr/bin/env bash
set -euo pipefail

# 1. Creazione directory temporanea univoca per l'esecuzione corrente
TMP_DIR=$(mktemp -d /tmp/bao_ssh.XXXXXX)

# Rimozione automatica delle chiavi temporanee all'uscita dallo script (anche in caso di errore)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

KEY_PATH="$TMP_DIR/id_ed25519"
CERT_PATH="$TMP_DIR/id_ed25519-cert.pub"

# 2. Generazione chiave ED25519 senza passphrase e con redirect da /dev/null
ssh-keygen -q -t ed25519 -N "" -f "$KEY_PATH" < /dev/null

# 3. Richiesta del certificato firmato a OpenBao/Vault
# Nota: BAO_ADDR e BAO_TOKEN devono essere esportati nelle variabili d'ambiente di Semaphore UI
OPENBAO_ROLE="${OPENBAO_SSH_ROLE:-ansible-role}"

bao write -field=signed_key ssh/sign/"$OPENBAO_ROLE" \
    public_key=@"${KEY_PATH}.pub" \
    valid_principals="ansible" > "$CERT_PATH"

# 4. Sostituzione del processo corrente con SSH (evita processi bash orfani)
exec ssh \
  -i "$KEY_PATH" \
  -o CertificateFile="$CERT_PATH" \
  "$@"
