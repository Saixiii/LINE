#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           04/04/2016
##  Function:       Admin jboss
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

DATE=`date +"%d-%m-%y %H:%M:%S"`
PID_ID=$$

FILE_CONFIG=/home/mstm/botline/conf/sbmjboss.conf

WAIT_TIMEOUT=300
WAIT_INTERVAL=15

JBOSS_PATH=/home/mstm/script/jboss/bin
JBOSS_SCRIPT=${JBOSS_PATH}/jboss-cli.sh
JBOSS_USER=admin
JBOSS_PASS=admin
JBOSS_TIMEOUT=15000

MBYTE=1048576


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
   echo "statjboss <Instance>"
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
JBOSS_HEAP="/host=${JBOSS_NODE}/server=${JBOSS_SERVER}/core-service=platform-mbean/type=memory :read-attribute(name=heap-memory-usage)"
JBOSS_THREAD="/host=${JBOSS_NODE}/server=${JBOSS_SERVER}/core-service=platform-mbean/type=threading :read-resource(include-runtime=true)"

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Function    : func_Heap
# Description : Check Jboss heap
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_Heap() {
   CMD_DATA=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_HEAP}"`
   CMD_RESULT=`echo "${CMD_DATA}" |grep outcome |awk -F'"' '{print $4}'`
   if [ ${CMD_RESULT} == "success" ]
   then
      INIT=`echo "${CMD_DATA}" |grep init |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      USED=`echo "${CMD_DATA}" |grep used |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      COMMIT=`echo "${CMD_DATA}" |grep committed |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      MAX=`echo "${CMD_DATA}" |grep max |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      M_INIT=`echo "${INIT}/${MBYTE}" |bc`
      M_USED=`echo "${USED}/${MBYTE}" |bc`
      M_COMMIT=`echo "${COMMIT}/${MBYTE}" |bc`
      M_MAX=`echo "${MAX}/${MBYTE}" |bc`
      echo "Heap: ${M_USED}/${M_MAX} MB"
   else
      echo "Cannot check stat server : ${JBOSS_SERVER} ($CMD_RESULT)"
      exit 0
   fi
}

#-------------------------------------------------------------------------------
# Function    : func_Thread
# Description : Check Jboss thread
# Parameters  : Message
# Return      : <None>
#-------------------------------------------------------------------------------
func_Thread() {
   CMD_DATA=`${JBOSS_SCRIPT} --controller=${JBOSS_IP}:${JBOSS_PORT} --connect --user=${JBOSS_USER} --password=${JBOSS_PASS} --timeout=${JBOSS_TIMEOUT} "${JBOSS_THREAD}"`
   CMD_RESULT=`echo "${CMD_DATA}" |grep outcome |awk -F'"' '{print $4}'`
   if [ ${CMD_RESULT} == "success" ]
   then
      ACTIVE=`echo "${CMD_DATA}" |grep "\"thread-count\"" |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      PEAK=`echo "${CMD_DATA}" |grep "\"peak-thread-count\"" |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      DAEMON=`echo "${CMD_DATA}" |grep "\"daemon-thread-count\"" |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1}'`
      CPU=`echo "${CMD_DATA}" |grep "\"current-thread-cpu-time\"" |awk '{print $3}' |awk -F 'L' '{print $1}' |awk -F ',' '{print $1/1000000000}'`
      echo "CPU: ${CPU}%"
      echo "Threads Active: ${ACTIVE}"
      echo "Threads Daemon: ${DAEMON}"
      echo "Threads Peak: ${PEAK}"
   else
      echo "Cannot check stat server : ${JBOSS_SERVER} ($CMD_RESULT)"
      exit 0
   fi
}



#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

TIME_MIN=0

echo "Server: ${JBOSS_SERVER}"
echo ""

func_Heap
func_Thread
