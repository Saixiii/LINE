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

JBOSS_PATH=/home/mstm/botline/bin
JBOSS_START=${JBOSS_PATH}/startjboss.sh
JBOSS_STOP=${JBOSS_PATH}/stopjboss.sh
JBOSS_TERMINATE=${JBOSS_PATH}/terminatejboss.sh
JBOSS_RESTART=${JBOSS_PATH}/restartjboss.sh

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "$1 <Instance>"
   printf "Require  : <Instance> ["
   cat ${FILE_CONFIG} |awk -F, '{if($8!="") print $1}' |tr '\n' '|'
   echo "]"
   exit
}

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

if [ -z "$2" ]
then
  func_Usage $1
fi

INPUT_APP=$2
COUNT_APP=`cat ${FILE_CONFIG} |awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if(($1==s)&&($8!="")&&($9!="")) print $0}'|wc -l`

if [ ${COUNT_APP} != "1" ]
then
  func_Usage $1
fi

JBOSS_COM=$1
JBOSS_SERVER=$2

if [ ${JBOSS_COM} == "start" ]
then
   ${JBOSS_START} ${JBOSS_SERVER} &>/dev/null &
   disown
elif [ ${JBOSS_COM} == "stop" ]
then
   ${JBOSS_STOP} ${JBOSS_SERVER} &>/dev/null &
   disown
elif [ ${JBOSS_COM} == "terminate" ]
then
   ${JBOSS_TERMINATE} ${JBOSS_SERVER} &>/dev/null &
   disown
elif [ ${JBOSS_COM} == "restart" ]
then
   ${JBOSS_RESTART} ${JBOSS_SERVER} &>/dev/null &
   disown
fi

echo "Process is running ${JBOSS_COM} on ${JBOSS_SERVER}"
