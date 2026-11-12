#!/bin/bash
# Consumer for one node of the active/active pair. Run one copy per node and
# both drain the same cluster queue at the same time.
set -euo pipefail

MQ_CHANNEL="${MQ_CHANNEL:-HA.SVRCONN}"
MQ_CONNAMES="${MQ_CONNAMES:-qm1(1414)}"
MQ_QUEUE="${MQ_QUEUE:-HA.Q}"
POLL_SECONDS="${POLL_SECONDS:-2}"
STARTUP_DELAY_SECONDS="${STARTUP_DELAY_SECONDS:-0}"
MQ_SAMPLES="${MQ_SAMPLES:-/opt/mqm/samp/bin}"
NODE_LABEL="${NODE_LABEL:-${MQ_CONNAMES}}"

export MQSERVER="${MQ_CHANNEL}/TCP/${MQ_CONNAMES}"

if [ "${STARTUP_DELAY_SECONDS}" -gt 0 ]; then
    echo "[${NODE_LABEL}] sleeping ${STARTUP_DELAY_SECONDS}s before consuming ${MQ_QUEUE}"
    sleep "${STARTUP_DELAY_SECONDS}"
fi

echo "consuming ${MQ_QUEUE} via ${MQSERVER}"
last_error=""
while :; do
    # amqsgetc returns once the queue is empty, so poll in a loop.
    output=$("${MQ_SAMPLES}/amqsgetc" "${MQ_QUEUE}" 2>&1) || true

    # Messages already retrieved are reported even if the node then fails.
    printf '%s\n' "${output}" |
        sed -n 's/^message <\(.*\)>$/['"${NODE_LABEL}"'] consumed: \1/p' || true

    # Report a failure once instead of on every poll while the node is down.
    error=$(printf '%s\n' "${output}" | grep 'reason code' | tail -1 || true)
    if [ -n "${error}" ] && [ "${error}" != "${last_error}" ]; then
        echo "[${NODE_LABEL}] ${error}"
        last_error="${error}"
    fi

    sleep "${POLL_SECONDS}"
done
