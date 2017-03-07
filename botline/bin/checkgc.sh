#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           22/07/2015
##  Function:       Check fullGC Websphere Application Server
##===============================================================================##

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

PID_ID=$$

PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

FILE_CONFIG="${PATH_CONFIG}/sbmwas.conf"
FILE_LIST="${PATH_LOG}/CheckWASGC.${PID_ID}"

SBM_APP="$1"

if [ -z "$1" ]
then
   echo "Usage : checkgc <List: sbm|topping|3g>"
   echo "Usage : checkgc <Application: 3G-S2|3G-S3|3G-S4|3G-S5|Admin|ATB|VMS|BB|CCAS|CMB|DBF|FCR|CRC|FIXEDIP|Google|HS|IDDR|IR|NCB|IOU|IVP|NVCPRE|IVRPM|PM|SPAM|Magngo|MNV|NVC|OTAMNP|PPREGIS|RBT>"
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
# Function    : func_GetConfigInfo
# Description : Get data configure WAS from file
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_GetConfigByApp() {
APP=$1
cat ${FILE_CONFIG} |awk -F, -v s="$APP" '{IGNORECASE = 1;if(($3~s)||($1~s)) print $0}'|sort  > ${FILE_LIST}
}

#-------------------------------------------------------------------------------
# Function    : func_GetConfigByWAS
# Description : Get data configure WAS from file
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_GetConfigByWAS() {
WAS=$1
cat ${FILE_CONFIG} |awk -F, -v s="$WAS" '{IGNORECASE = 1;if($2==s) print $0}'|sort  > ${FILE_LIST}
}




#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

func_VerfiyOwnProcess

if [ "$SBM_APP" == sbm ] || [ "$SBM_APP" == topping ] || [ "$SBM_APP" == 3g ]
then
  func_GetConfigByWAS ${SBM_APP}
else
  func_GetConfigByApp ${SBM_APP}
fi

for line in $(cat ${FILE_LIST})
do
   SERVER=`echo $line |awk -F, '{print $1}'`
   DMGR=`echo $line |awk -F, '{print $2}'`
   APP=`echo $line |awk -F, '{print $3}'`
   IP=`echo $line |awk -F, '{print $4}'`
   PORT=`echo $line |awk -F, '{print $5}'`
   USER=`echo $line |awk -F, '{print $6}'`
   PATH_WAS=`echo $line |awk -F, '{print $7}'`
   echo "Server : ${SERVER}"
   echo "APP : ${APP}"
   ssh -p ${PORT} ${USER}@${IP} tail -5000 ${PATH_WAS}/${SERVER}/native_stdout.log |grep -i gc |tail -3 |awk -F'[' '{print $2}' |awk '{if($1=="GC") print $1" " $3" s.";else print $1$2" "$4" s."}'
   echo "================="
done


rm ${FILE_LIST}
