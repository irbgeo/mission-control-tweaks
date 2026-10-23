#!/bin/bash
# Creates a free self-signed code-signing certificate "MCTweaks Self-Signed".
# Signing every release with it keeps the user's Accessibility permission after updates.
# It does NOT remove the macOS "unverified developer" warnings (only an Apple Developer ID does).
# Run once; keep build/signing/ private and out of git. Usage: scripts/make-signing-cert.sh [dir]
set -euo pipefail

NAME="MCTweaks Self-Signed"
DIR="${1:-build/signing}"
OPENSSL=/usr/bin/openssl # LibreSSL: its PKCS#12 format is the one macOS "security import" reads

if [ -e "$DIR/mctweaks.p12" ]; then
    echo "$DIR/mctweaks.p12 already exists. Delete it first if you really want a new certificate:"
    echo "a new certificate makes every user grant Accessibility again."
    exit 1
fi

mkdir -p "$DIR"
chmod 700 "$DIR"
cat > "$DIR/cert.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF

# The password goes through a file, never the command line (other processes can read command lines).
(umask 077 && $OPENSSL rand -base64 24 | tr -d '\n' > "$DIR/password.txt")
$OPENSSL req -x509 -newkey rsa:2048 -days 3650 -nodes \
    -config "$DIR/cert.cnf" -keyout "$DIR/key.pem" -out "$DIR/cert.pem" 2>/dev/null
$OPENSSL pkcs12 -export -name "$NAME" -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
    -out "$DIR/mctweaks.p12" -passout "file:$DIR/password.txt"
rm "$DIR/key.pem"
chmod 600 "$DIR"/*

echo "Created $DIR/mctweaks.p12 (password in $DIR/password.txt)."
echo
echo "Add it to GitHub (run in this repo):"
echo "  base64 -i $DIR/mctweaks.p12 | gh secret set SIGNING_CERT_P12_BASE64"
echo "  gh secret set SIGNING_CERT_PASSWORD < $DIR/password.txt"
echo
echo "Optional, to sign local builds the same way:"
echo "  security import $DIR/mctweaks.p12 -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign   # asks for the password from $DIR/password.txt"
echo "  make install SIGN_ID=\"$NAME\""
echo
echo "Keep a backup of $DIR/mctweaks.p12 and the password in a safe place."
