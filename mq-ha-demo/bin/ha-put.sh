#!/bin/bash
# Producer for the active/active pair.
#
# MQSERVER accepts a comma-separated connection list, so every connection is
# spread over both queue managers and survives one of them failing.
set -euo pipefail

MQ_CHANNEL="${MQ_CHANNEL:-HA.SVRCONN}"
MQ_CONNAMES="${MQ_CONNAMES:-qm1(1414),qm2(1414)}"
MQ_QUEUE="${MQ_QUEUE:-HA.Q}"
MESSAGE_COUNT="${MESSAGE_COUNT:-10}"
CLUSTER_SETTLE_SECONDS="${CLUSTER_SETTLE_SECONDS:-15}"
MQ_SAMPLES="${MQ_SAMPLES:-/opt/mqm/samp/bin}"

export MQSERVER="${MQ_CHANNEL}/TCP/${MQ_CONNAMES}"

# Cluster convergence is asynchronous: a queue manager only routes to the peer
# once the repositories have been exchanged, otherwise messages stay local.
echo "waiting ${CLUSTER_SETTLE_SECONDS}s for the cluster to converge"
sleep "${CLUSTER_SETTLE_SECONDS}"

echo "producing ${MESSAGE_COUNT} messages to ${MQ_QUEUE} via ${MQSERVER}"
for i in $(seq 1 "${MESSAGE_COUNT}"); do
    output=$(printf 'message %02d from %s\n' "${i}" "${HOSTNAME}" |
        "${MQ_SAMPLES}/amqsputc" "${MQ_QUEUE}" 2>&1) || true
    case "${output}" in
    *"reason code"*)
        printf '%s\n' "${output}"
        exit 1
        ;;
    esac
    echo "put message ${i}/${MESSAGE_COUNT}"
done
echo "done - check the queue depth on both queue managers"
