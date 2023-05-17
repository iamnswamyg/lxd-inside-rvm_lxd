#!/bin/bash
TEST_SERVERS="ufcolo1-dbshard1 ufcolo1-dbshard2 ufcolo2-dbshard1 ufcolo2-dbshard2"

function quit {
  echo "$(date) failed"
  exit 1
}
salt -L "${TEST_SERVERS}" --async cmd.run "ufdeploy-test-synch.sh"
for (( COUNT=0; COUNT < 100; COUNT++ )); do
  echo "$(date) Count: $COUNT"
  ufdeploy-coordinator --key "TEST-XXX" --timeout=10 --port=8283 ${TEST_SERVERS} || quit
  echo "------------------------------------------------"
done

echo "$(date) done"
