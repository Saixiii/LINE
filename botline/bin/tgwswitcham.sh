!/usr/bin/sh -x
##===============================================================================##
##  Author:         Thanaroj Ratanamungmeka [KLa] 
##  Date:           21/10/2016
##  Function:      TGW Switch AM Site
##===============================================================================##
. /home/mstm/.bash_profile


#-------------------------------------------------------------------------------
#     O R A C L E   E N V I R O N M E N T
#-------------------------------------------------------------------------------

export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME/network/admin/tnsnames.ora
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_USER=TGW
export ORACLE_PASS=tgw132
export ORACLE_SID=RMV_TGW

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

tgw_option="$1"

if [ -z "$1" ]
then
   echo "Usage : $(basename $0)  <PBI|MTG>  *Sensitive Case*"
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

if [ "${tgw_option}" == "PBI" ]
then
{
AM_URL="http://suramapp14210.rmv:10004/services/XMLHTTPService_RMVOCS"
}
elif [ "${tgw_option}" == "MTG" ]
then
{
AM_URL="http://suramapp10004.rmv:10004/services/XMLHTTPService_RMVOCS"
}
else
{
AM_URL="http://suramapp10004.rmv:10004/services/XMLHTTPService_RMVOCS"
}
fi


sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF 
set echo off
set pages 0
set feedback off
set underline off
set trims on
set linesize 1500 

update global_config
set  CONFIG_VALUE = '${AM_URL}'
where gc_id = '735';
commit;
exit;
EOF

 sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF 
set echo off
set pages 0
set feedback off
set underline off
set trims on
set linesize 1500 

select CONFIG_VALUE
from global_config
where gc_id = '735';
exit;
EOF
