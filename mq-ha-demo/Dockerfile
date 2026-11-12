# IBM MQ "active/active" HA demo.
#
# Both queue managers are full repositories of one cluster and both host the
# same cluster queue, so producers and consumers can use either node - or both
# at the same time. Build the same Dockerfile once per cluster member:
#
#   docker build --build-arg QMGR_NAME=QM1 --build-arg PEER_QMGR_NAME=QM2 \
#                --build-arg SELF_CONNAME=qm1(1414) --build-arg PEER_CONNAME=qm2(1414) \
#                -t mqha:qm1 .
#
# Note: clustering gives active/active messaging, not shared storage. Messages
# on a node are unavailable while that node is down; use multi-instance queue
# managers (MQ_MULTI_INSTANCE) on shared storage if you need that instead.
#
# The same image runs the demo clients - see compose.yaml.

FROM icr.io/ibm-messaging/mq:10.0.1.0-r1

ARG QMGR_NAME=QM1
ARG PEER_QMGR_NAME=QM2
ARG SELF_CONNAME=qm1(1414)
ARG PEER_CONNAME=qm2(1414)
ARG CLUSTER_NAME=MQHA
ARG QUEUE_NAME=HA.Q
ARG CHANNEL_NAME=HA.SVRCONN

USER root

# Low-privilege identity for messaging clients - the MQSC script maps every
# client connection to it. UBI-minimal has no useradd, so edit the files.
RUN grep -q '^app:' /etc/passwd || \
    (echo 'app:x:2000:2000::/home/app:/sbin/nologin' >> /etc/passwd && \
     echo 'app:x:2000:' >> /etc/group)

COPY bin/ /usr/local/bin/
COPY mqsc/ /usr/local/share/mqsc/

# The container entrypoint replays /etc/mqm/*.mqsc (in name order) when the
# queue manager is created, so the cluster objects are declarative.
RUN chmod 755 /usr/local/bin/ha-put.sh /usr/local/bin/ha-consume.sh \
    && sed -e "s|@QMGR_NAME@|${QMGR_NAME}|g" \
           -e "s|@PEER_QMGR_NAME@|${PEER_QMGR_NAME}|g" \
           -e "s|@SELF_CONNAME@|${SELF_CONNAME}|g" \
           -e "s|@PEER_CONNAME@|${PEER_CONNAME}|g" \
           -e "s|@CLUSTER_NAME@|${CLUSTER_NAME}|g" \
           -e "s|@QUEUE_NAME@|${QUEUE_NAME}|g" \
           -e "s|@CHANNEL_NAME@|${CHANNEL_NAME}|g" \
           /usr/local/share/mqsc/30-ha-cluster.mqsc > /etc/mqm/30-ha-cluster.mqsc

USER 1001

ENV LICENSE=accept \
    MQ_QMGR_NAME=${QMGR_NAME}

HEALTHCHECK --interval=5s --timeout=5s --start-period=20s --retries=24 \
    CMD chkmqready
