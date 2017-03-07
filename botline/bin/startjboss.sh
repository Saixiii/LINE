#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           04/02/2016
##  Function:       Admin jboss
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

DATE=`date +"%d-%b-%y %H:%M:%S"`
PID_ID=$$

FILE_CONFIG=/home/mstm/botline/conf/sbmjboss.conf

WAIT_TIMEOUT=300
WAIT_INTERVAL=15

JBOSS_PATH=/home/mstm/script/jboss/bin
JBOSS_SCRIPT=${JBOSS_PATH}/jboss-cli.sh
JBOSS_USER=admin
JBOSS_PASS=admin
JBOSS_TIMEOUT=15000

LINE_SCRIPT="/home/mstm/botline/bot/LineClient.py"
LINE_GROUP="SBM Support"


#-------------------------------------------------------------------------------
#     I N I T I A L
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "startjboss <Instance>"
   printf "Require  : <Instance> ["
   cat ${FILE_CONFIG} |awk -F, '{if($8!="") print $1}' |tr '\n' '|'
   echo "]"
   exit
}


if [ -z "$1" ]
then
  func_Usage
fi

INPUT_APP=$1
COUNT_APP=`cat ${FILE_CONFIG} |awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if(($1==s)&&($8!="")&&($9!="")) print $0}'|wc -l`

if [ ${COUNT_APP} != "1" ]
then
  func_Usage
fi

JBOSS_IP=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $8}'`
JBOSS_PORT=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $9}'`
JBOSS_SERVER=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $1}'`
JBOSS_NODE=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $10}'`

# Generate Command Line
JBOSS_STATUS="/host=${JBOSS_NODE}/server-config=${JBOSS_SERVER}/ :read-attribute(name=status)"
JBOSS_START="/host=${JBOSS_NODE}/server-config=${JBOSS_SERVER} :start"
JBOSS_STOP="/host=${JBOSS_NODE}/server-config=${JBOSS_SERVER} :stop"


#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Function    : func_LINE
# Description : Send LINE message
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_LINE() {
   SYSDATE=`date +"[%d-%m-%Y %H:%M:%S]"`
   LINE_MSG=`echo -e "${SYSDATE}\n$1"`
   ${LINE_SCRIPT} -g "${LINE_GROUP}" -m "${LINE_MSG}"
}

#-------------------------------------------------------------------------------
# Function    : func_Stopjboss
# Description : Stop jboss server
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_Stopjboss() {
   APP_STOP=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_STOP}"`
   CMD_RESULT=`echo "${APP_STOP}" |grep outcome |awk -F'"' '{print $4}'`
   if [ ${CMD_RESULT} == "success" ]
   then
      # 0 = true
      return 0
   fi
      # 1 = false
      return 1
}

#-------------------------------------------------------------------------------
# Function    : func_Startjboss
# Description : Start jboss server
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_Startjboss() {
   APP_START=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_START}"`
   CMD_RESULT=`echo "${APP_START}" |grep outcome |awk -F'"' '{print $4}'`
   if [ ${CMD_RESULT} == "success" ]
   then
      # 0 = true
      return 0
   fi
      # 1 = false
      return 1
}

#-------------------------------------------------------------------------------
# Function    : func_CheckStart
# Description : Check Jboss stop
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_CheckStart() {
   APP_STATUS=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_STATUS}"`
   CMD_RESULT=`echo "${APP_STATUS}" |grep result |awk -F'"' '{print $4}'`
   if [ ${CMD_RESULT} == "STARTED" ]
   then
      # 0 = true
      return 0
   fi
      # 1 = false
      return 1
}



#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

TIME_MIN=0

if func_CheckStart
then
   func_LINE "StartJboss:\nServer has been started on nodename=${JBOSS_NODE}, servername=${JBOSS_SERVER}"
elif func_Startjboss
then
   while :
   do
      sleep ${WAIT_INTERVAL}
      TIME_MIN=$((TIME_MIN+WAIT_INTERVAL))
      if func_CheckStart
      then
         func_LINE "StartJboss:\nStart complete on nodename=${JBOSS_NODE}, servername=${JBOSS_SERVER} maxwaitseconds=${WAIT_TIMEOUT} elapsedtimeseconds=${TIME_MIN}"
         break
      fi
      if [ ${TIME_MIN} -gt ${WAIT_TIMEOUT} ]
      then
         func_LINE "StartJboss:\nWaiting time is over to start on nodename=${JBOSS_NODE}, servername=${JBOSS_SERVER} maxwaitseconds=${WAIT_TIMEOUT} elapsedtimeseconds=${TIME_MIN}"
         break
      fi
      func_LINE "StartJboss:\nWaiting ${TIME_MIN} of ${WAIT_TIMEOUT} seconds for ${JBOSS_SERVER} to start."
   done
else
   func_LINE "StartJboss:\nFail to excetued start command on nodename=${JBOSS_NODE}, servername=${JBOSS_SERVER}"
fi
