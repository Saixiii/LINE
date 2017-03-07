#!/usr/bin/sh
##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           26/10/2016
##  Function:       Check wakeup queue SBM
##===============================================================================##

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

PID_ID=$$

DATE=`date +"%d-%b-%y %H:%M:%S"`
PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"

FILE_CONFIG="${PATH_CONFIG}/sbmdb.conf"
SQL_QUEUE="${PATH_LOG}/SQL_SBM_QUEUE.${PID_ID}"

SBM_APP="$1"

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
   echo "queuesbm <App>"
   printf "Require  : <App> ["
   cat ${FILE_CONFIG} |awk -F, '{print $1}' |tr '\n' '|'
   echo "]"
   exit
}


if [ -z "$1" ]
then
  func_Usage
fi

INPUT_APP=$1
COUNT_APP=`cat ${FILE_CONFIG} |awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $0}'|wc -l`

if [ ${COUNT_APP} != "1" ]
then
  func_Usage
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
   echo "[${DATE}]"
   echo "Too much request process pending !!!"
   exit
fi
}

#-------------------------------------------------------------------------------
# Function    : func_OracleEnv
# Description : Export oracle environment
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_OracleEnv() {
   export ORACLE_HOME=/usr/lib/oracle/11.2/client64
   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export TNS_ADMIN=$ORACLE_HOME/network/admin/tnsnames.ora
   export PATH=$ORACLE_HOME/bin:$PATH
}


#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

func_VerfiyOwnProcess
func_OracleEnv

SBM_USER=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $2}'`
SBM_PASS=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $3}'`
SBM_TNS=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_APP" '{IGNORECASE = 1;if($1==s) print $4}'`


echo "[${DATE}]" > ${SQL_QUEUE}
echo "Wakeup Queue ${SBM_APP}" >> ${SQL_QUEUE}
sqlplus -s "$SBM_USER/$SBM_PASS@$SBM_TNS" << EOF |awk '{print $0}' >> ${SQL_QUEUE}
SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET PAGES 0
SET TRIMS ON
SET LINESIZE 9999
SELECT 'Queue : '||COUNT(*)
FROM TRANSACTIONS
WHERE WAKEUP_TIME < SYSDATE;
EOF

cat ${SQL_QUEUE}

rm ${SQL_QUEUE}
