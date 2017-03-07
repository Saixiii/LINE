#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           11/08/2015
##  Function:       Get stat JVM
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

DATE=`date +"%d-%b-%y %H:%M:%S"`
PID_ID=$$

FILE_CONFIG=/home/mstm/botline/conf/sbmwas.conf

WAS_PATH=/home/mstm/script/websphere
WAS_SCRIPT=${WAS_PATH}/wsadmin.sh
WAS_FILE=${WAS_PATH}/LineStatJVM.py
WAS_USER=wasadmin
WAS_PASS=wasadmin

#-------------------------------------------------------------------------------
#     F U N C T I O N S
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "checkjvm <Instance>"
   printf "Require  : <Instance> ["
   cat ${FILE_CONFIG} |awk -F, '{if($8!="") print $1}' |tr '\n' '|'
   echo "]"
   exit
}

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

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

WAS_IP=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $8}'`
WAS_PORT=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $9}'`
WAS_SERVER=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $1}'`

${WAS_SCRIPT} -lang jython -user ${WAS_USER} -password ${WAS_PASS} -host ${WAS_IP} -port ${WAS_PORT} -f ${WAS_FILE} ${WAS_SERVER} &>/dev/null &

disown
echo "Process is checking JVM ${WAS_SERVER}"