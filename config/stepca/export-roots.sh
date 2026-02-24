#!/bin/sh
set -eu

OUT_ROOTS="/export/roots.pem"
OUT_ROOTCRT="/export/root_ca.crt"

CA_HEALTH="https://stepca:9000/health"
CA_ROOTS="https://stepca:9000/roots.pem"

# If both artifacts already exist and are non-empty, skip export.
if [ -s "$OUT_ROOTS" ] && [ -s "$OUT_ROOTCRT" ]; then
  echo "roots.pem + root_ca.crt exist, skip"
  exit 0
fi

echo "waiting for stepca..."

i=0
while [ $i -lt 60 ]; do
  if wget -q --no-check-certificate -O /dev/null "$CA_HEALTH" 2>/dev/null; then
    break
  fi
  i=$((i+1))
  sleep 1
done

if [ $i -eq 60 ]; then
  echo "stepca not reachable"
  exit 1
fi

echo "exporting roots..."
wget -q --no-check-certificate -O "$OUT_ROOTS" "$CA_ROOTS"

# Derive root_ca.crt from roots.pem (same PEM bundle; exported for client trust convenience)
cp "$OUT_ROOTS" "$OUT_ROOTCRT"

echo "exported:"
echo " - $OUT_ROOTS"
echo " - $OUT_ROOTCRT"
