#!/usr/bin/sh
##===============================================================================##
##  Author:         Thanaroj Ratanamungmeka [KLa] 
##  Date:           10/09/2014
##  Function:       Check APP/Instance
##===============================================================================##
. /home/mstm/.bash_profile


#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

founded="$1"

if [ -z "$1" ]
then
   echo "Usage : $(basename $0)  <Instance|APP|IP>"
   exit
fi

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
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------
func_VerfiyOwnProcess

cat ${PATH_SCRIPT}/ftppooluser.txt | grep -i $1
