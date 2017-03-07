#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           29/07/2015
##  Function:       Get TGW queue
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

# Mode

PID_ID=$$
DATE=`date +"%d-%b-%y %H:%M:%S"`
PARDATE=`date +"%Y%m%d"`

# Local config
PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"
SQL_QUEUE="${PATH_LOG}/SQL_TGW_QUEUE.${PID_ID}"
SQL_LIST="${PATH_LOG}/SQL_TGW_LIST.${PID_ID}"

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "queuetgw <DSQ>"
   printf "["
   cat ${SQL_LIST} |tr '\n' '|'
   echo "]"
   rm ${SQL_LIST}
   exit
}


#-------------------------------------------------------------------------------
# Function    : func_VerfiyOwnProcess
# Description : Verify and kill own pending process
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_VerfiyOwnProcess() {
PROC_COUNT=`ps -ef |grep $(basename $0) |egrep -v "grep|$$|vi|cat|more|tail" |awk '{print $2}' |wc -l|awk '{print $1}'`
if [ ${PROC_COUNT} -gt 2 ]
then
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
   export ORACLE_USER=tgw
   export ORACLE_PASS=tgw132
   export ORACLE_SID=RMV_TGW
}

#-------------------------------------------------------------------------------
# Function    : func_SQLList
# Description : SQL*PLUS List data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLList() {
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF > ${SQL_LIST}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
SELECT DEST_TABLE
FROM DESTINATION
ORDER BY CREATE_DATE;
EOF
}

#-------------------------------------------------------------------------------
# Function    : func_SQLQuery
# Description : SQL*PLUS Query data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLQuery() {
   DB_TABLE=$1
   echo "TGW : ${DB_TABLE}" > ${SQL_QUEUE}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF |awk '{print $0}' >> ${SQL_QUEUE}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
SELECT 'Queue : '||COUNT(*)
FROM TGW.${DB_TABLE}
WHERE STATUS <> 'S'
AND STATUS <> 'SA'
AND STATUS <> 'SI';
EOF
}

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

# Verify pending process
func_VerfiyOwnProcess

# Export oracle environment
func_OracleEnv

# List service name
func_SQLList

INPUT_SERVICE=$1

if [ -z "$1" ]
then
  func_Usage
fi

# Query USSD
func_SQLQuery ${INPUT_SERVICE}
cat ${SQL_QUEUE}

rm ${SQL_LIST} ${SQL_QUEUE}
