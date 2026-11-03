#!/bin/sh
# Seal fork-CI: keep the job open until Travis has archived this job's log
# through the script phase's result line. The harness downloads each job's log
# as soon as the build finishes, and Travis archives log parts asynchronously
# (minutes behind the job), so without this the harvested log can stop before
# the test summary. after_script cannot change the build result.
# Polls the public log of this job every 20 s, capped at 15 min, printing a
# progress line on every poll: a silent wait would trip Travis's 10-minute
# no-output watchdog (job "errored"), and new output also lets Travis flush
# the pending log parts.
done_re='The command ".*" exited with [0-9]+\.'
i=0
while [ "$i" -lt 45 ]; do
  for url in "https://api.travis-ci.com/v3/job/${TRAVIS_JOB_ID}/log.txt" \
             "https://api.travis-ci.com/job/${TRAVIS_JOB_ID}/log.txt"; do
    if curl -sfL -H "Travis-API-Version: 3" "$url" -o /tmp/seal-own-log.txt 2>/dev/null \
       && grep -Eq "$done_re" /tmp/seal-own-log.txt; then
      echo "seal: job log archived through the script result after $((i * 20)) s ($(wc -l < /tmp/seal-own-log.txt) lines)"
      exit 0
    fi
  done
  echo "seal: waiting for the job log archive ($((i * 20)) s, $(wc -l < /tmp/seal-own-log.txt 2>/dev/null || echo 0) lines so far)"
  i=$((i + 1))
  sleep 20
done
echo "seal: job log not archived through the script result after 15 min"
exit 0
