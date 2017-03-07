#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           13/07/2015
##  Function:       Monitor Websphere Application Server Status
##===============================================================================##

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------
PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

SBM_WAS="$1"

if [ -z "$1" ]
then
   echo "Usage : $(basename $0) <sbm|topping|3g|3git>"
   exit
fi

IP_SBM=10.95.98.134
IP_TOPPING=10.95.76.6
IP_3G=10.95.217.13
IP_3GIT=10.95.217.15


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

if [ "${SBM_WAS}" == "sbm" ]
then
  /usr/bin/timeout 60 ssh -p40 sssusr@${IP_SBM} '/export/home/nagios/bin/list_websphere_status.sh' |awk '{if(substr($1,1,3)=="App") print $1" - "$2}' |sed 's/AppSbmReal/Sbm/g' |sort
elif [ "${SBM_WAS}" == "topping" ]
then
  /usr/bin/timeout 60 ssh -p40 sssusr@${IP_TOPPING} '/export/home/nagios/bin/list_websphere_status.sh' |awk '{if(substr($1,1,3)=="App") print $1" - "$2}' |sed 's/AppToppingReal/Topping/g' |sort
elif [ "${SBM_WAS}" == "3g" ]
then
  /usr/bin/timeout 60 ssh -p40 sssusr@${IP_3G} '/export/home/nagios/bin/list_websphere_status.sh' |awk '{if(substr($1,1,3)=="SBM") print $1" - "$2}' |sed 's/SBM03-D01-App/SBM03-/g' |sort
elif [ "${SBM_WAS}" == "3git" ]
then
  /usr/bin/timeout 60 ssh -p40 sssusr@${IP_3GIT} '/export/home/nagios/bin/list_websphere_status.sh' |awk '{if(substr($1,1,3)=="SBM") print $1" - "$2}' |sed 's/SBM04-D01-App/SBM04-/g' |sort
else
  echo "Usage : $(basename $0) <sbm|topping|3g|3git>"
fi
