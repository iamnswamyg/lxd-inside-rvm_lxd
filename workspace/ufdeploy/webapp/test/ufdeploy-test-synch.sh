#!/bin/bash
function quit {
  echo "$(date) failed"
  exit 1
}

for (( COUNT=0; COUNT < 100; COUNT++ )); do
  echo "$(date) Count: $COUNT"
  sleep 1
  ufdeploy-synchronizer --key "TEST-XXX" --accept 10 --wait 10  --addr :8283 || quit
done

echo "$(date) done"
