#!/usr/bin/sh -x

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           04/02/2016
##  Function:       Get status jboss
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

DATE=`date +"%d-%b-%y %H:%M:%S"`
PID_ID=$$

FILE_CONFIG=/home/mstm/botline/conf/sbmjboss.conf

JBOSS_PATH=/home/mstm/script/jboss/bin
JBOSS_SCRIPT=${JBOSS_PATH}/jboss-cli.sh
JBOSS_USER=admin
JBOSS_PASS=admin
JBOSS_TIMEOUT=30000


#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

PRINT=""

while read line
do
  # Read Parameter
  JBOSS_IP=`echo ${line}|awk -F, '{print $8}'`
  JBOSS_PORT=`echo ${line}|awk -F, '{print $9}'`
  JBOSS_SERVER=`echo ${line}|awk -F, '{print $1}'`
  JBOSS_NODE=`echo ${line}|awk -F, '{print $10}'`
  
  # Generate Command Line
  JBOSS_CMD="/host=${JBOSS_NODE}/server-config=${JBOSS_SERVER}/ :read-attribute(name=status)"
  # Execute Jboss command
  JBOSS_RESULT=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_CMD}"`
  
  # Read Result
  CMD_RESULT=`echo "${JBOSS_RESULT}" |grep outcome |awk -F'"' '{print $4}'`
  JBOSS_STATUS="unknown"
  if [ ${CMD_RESULT} == "success" ]
  then
    JBOSS_STATUS=`echo "${JBOSS_RESULT}" |grep result |awk -F'"' '{print $4}'`
  fi
  
  PRINT="${PRINT}\n${JBOSS_SERVER} - ${JBOSS_STATUS}"
  
done < ${FILE_CONFIG} 

echo -e "${PRINT}"
