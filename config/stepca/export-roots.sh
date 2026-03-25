#!/bin/sh
set -eu

OUT_ROOTS="/export/roots.pem"
OUT_ROOTCRT="/export/root_ca.crt"

CA_ROOTS="https://stepca:9000/roots.pem"

# If both artifacts already exist and are non-empty, skip export.
if [ -s "$OUT_ROOTS" ] && [ -s "$OUT_ROOTCRT" ]; then
  echo "roots.pem + root_ca.crt exist, skip"
  exit 0
fi

echo "exporting roots..."
wget -q --no-check-certificate -O "$OUT_ROOTS" "$CA_ROOTS"

# Derive root_ca.crt from roots.pem (same PEM bundle; exported for client trust convenience)
cp "$OUT_ROOTS" "$OUT_ROOTCRT"

echo "exported:"
echo " - $OUT_ROOTS"
echo " - $OUT_ROOTCRT"
