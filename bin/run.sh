#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

ALIVE=0

export GLUSTER_PEERS=`dig +short ${SERVICE_NAME} | sort`
if [ -z "${GLUSTER_PEERS}" ]; then
   echo "*** ERROR: Could not determine which containers are part of this service."
   echo "*** Is this service named \"${SERVICE_NAME}\"? If not, please regenerate the service"
   echo "*** and add SERVICE_NAME environment variable which value should be equal to this service name"
   echo "*** Exiting ..."
   exit 1
else
   echo "${GLUSTER_PEERS}"
fi

for PEER in `echo "${GLUSTER_PEERS}" | sed "s/,/ /g"`; do
    echo "=> Checking if I can reach GlusterFS node ${PEER} ..."
    if ping -c 10 ${PEER} >/dev/null 2>&1; then
       echo "=> GlusterFS node ${PEER} is alive"
       ALIVE=1
       break
    else
       echo "*** Could not reach server ${PEER} ..."
    fi
done

if [ "$ALIVE" == 0 ]; then
   echo "ERROR: could not contact any GlusterFS node from this list: ${GLUSTER_PEERS} - Exiting..."
   exit 1
fi

echo "=> Mounting GlusterFS volume ${GLUSTER_VOL} from GlusterFS node ${PEER} ..."
mount -t glusterfs ${PEER}:/${GLUSTER_VOL} ${GLUSTER_VOL_PATH}

echo "=> Setting up site..."
if [ ! -d ${HTTP_DOCUMENTROOT} ]; then
   git clone https://github.com/bernardmaltais/demosite.git ${HTTP_DOCUMENTROOT}
   chown -R www-data:www-data ${HTTP_DOCUMENTROOT}
fi

#my_public_ip=`dig -4 @ns1.google.com -t txt o-o.myaddr.l.google.com +short | sed "s/\"//g"`
#perl -p -i -e "s/HOST = '.*'/HOST = '${my_public_ip}'/g" ${HTTP_DOCUMENTROOT}/client/config.js
#perl -p -i -e "s/PORT = .*;/PORT = ${GAME_SERVER_PORT};/g" ${HTTP_DOCUMENTROOT}/client/config.js

/usr/bin/supervisord
