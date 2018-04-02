#!/bin/sh
HOST=192.168.1.22
USER=zhangweijie
PASS=zwj@123456
echo "Starting to sftp..."
lftp -u ${USER},${PASS} sftp://${HOST} <<EOF
cd /usr/local/teamtalk/msg_server/
mput ./msg_server
bye
EOF
echo "done"

echo "Starting to ssh..."
sshpass -p ${PASS} ssh ${USER}@${HOST} "kill $(cat /usr/local/teamtalk/msg_server/server.pid)"
sshpass -p ${PASS} ssh ${USER}@${HOST} "gdbserver :2345  \"/usr/local/teamtalk/restart.sh msg_server\"" &
sleep 3
echo "done"