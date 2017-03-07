#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           14/11/2016
##  Function:       Check webserver thread Websphere
##===============================================================================##

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

PID_ID=$$

PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

FILE_CONFIG="${PATH_CONFIG}/sbmws.conf"
FILE_LIST="${PATH_LOG}/CheckWS.${PID_ID}"

SBM_APP="$1"

#-------------------------------------------------------------------------------
# Function    : func_VerfiyOwnProcess
# Description : Verify and kill own pending process
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_VerfiyOwnProcess() {
PROC_COUNT=`ps -ef |grep $(basename $0) |egrep -v "grep|$$|vi" |awk '{print $2}' |wc -l|awk '{print $1}'`
if [ ${PROC_COUNT} -gt 2 ]
then
   echo "Too much request process pending !!!"
   exit
fi
}

#-------------------------------------------------------------------------------
# Function    : func_GetConfig
# Description : Get data configure WS from file
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_GetConfig() {
WAS=$1
cat ${FILE_CONFIG} |awk -F, -v s="$WAS" '{IGNORECASE = 1;if($2==s) print $0}'|sort  > ${FILE_LIST}
}


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
   echo "statws <server>"
   printf "Require  : <server> ["
   cat ${FILE_CONFIG} |awk -F, '{if($2!="") print $2}' |sort |uniq |tr '\n' '|'
   echo "]"
   exit
}


if [ -z "$1" ]
then
  func_Usage
fi

INPUT_APP=$1
COUNT_APP=`cat ${FILE_CONFIG} |awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($2==s) print $0}'|wc -l`

if [ ${COUNT_APP} -lt "1" ]
then
  func_Usage
fi


#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

func_VerfiyOwnProcess

func_GetConfig ${SBM_APP}

for line in $(cat ${FILE_LIST})
do
   SERVER=`echo $line |awk -F, '{print $1}'`
   IP=`echo $line |awk -F, '{print $3}'`
   PORT=`echo $line |awk -F, '{print $4}'`
   USER=`echo $line |awk -F, '{print $5}'`
   PATH_WAS=`echo $line |awk -F, '{print $6}'`
   echo "Server : ${SERVER}"
   ssh -p ${PORT} ${USER}@${IP} tail -6 ${PATH_WAS}/error_log |grep rdy |awk '{print $4" - "$11}'
   echo "================="
done


rm ${FILE_LIST}
