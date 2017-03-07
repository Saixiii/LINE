#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           31/07/2015
##  Function:       Get error list services
##===============================================================================##

. /home/mstm/.bash_profile

#-------------------------------------------------------------------------------
#     G L O B A L    V A R I A B L E S
#-------------------------------------------------------------------------------

# Mode

PID_ID=$$

# Local config
PATH_HOME="/home/mstm/botline"
PATH_SCRIPT="${PATH_HOME}/bin"
PATH_CONFIG="${PATH_HOME}/conf"
PATH_LOG="${PATH_HOME}/log"
SQL_LIST="${PATH_LOG}/SQL_LIST_STM.${PID_ID}"
SQL_STAT="${PATH_LOG}/SQL_STAT_STM.${PID_ID}"

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "error <Service> <Interval> <Date>"
   printf "Require  : <Service> ["
   cat ${SQL_LIST} |tr '\n' '|'
   echo "]"
   echo "Optional : <Interval Minute> [10-1440]"
   echo "         : <Date> [YYYYMMDDHHMI]"
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
   export ORACLE_USER=stm
   export ORACLE_PASS=stm
   export ORACLE_SID=VASDB
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
SELECT SERVICE_NAME
FROM MAPPING_SERVICE
WHERE STATUS='Y'
ORDER BY UPDATE_DATE;
EOF
}

#-------------------------------------------------------------------------------
# Function    : func_SQLQuery
# Description : SQL*PLUS Query data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLQuery() {
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF  > ${SQL_STAT}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
select rownum||'|'||trim(to_char(total,'999,999,999,999'))||'|'||result_code||'|'||result_desc from (
select a.total,a.result_code,b.result_desc
from (
select result_code,service_name,sum(value) as total from report_data 
where service_name = upper('${INPUT_SERVICE}') 
and end_date >= to_date(rpad ('${INPUT_DATE}',14,0),'YYYYMMDDHH24MISS')
and end_date <= to_date(rpad ('${INPUT_DATE}',14,0),'YYYYMMDDHH24MISS') + ${INPUT_INTERVAL}/1440
group by result_code,service_name) a
left join mapping_result b
on a.service_name = b.service_name
and a.result_code = b.result_code
and b.service_name = upper('${INPUT_SERVICE}')
order by a.total desc
)
where rownum < 80;
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
INPUT_INTERVAL=$2
INPUT_DATE=$3

if [ -z "$1" ]
then
  func_Usage
fi

if [ -z "$2" ]
then
  INPUT_INTERVAL="60"
elif [ $2 -lt 10 ] || [ $2 -gt 1440 ]
then
  func_Usage
fi

if [ -z "$3" ]
then
   INPUT_DATE=`date --date "-${INPUT_INTERVAL} mins" +"%Y%m%d%H%M"`
fi


# Query USSD
func_SQLQuery

DB_QUEUE=`cat ${SQL_STAT}|wc -l|awk '{print $1}'`
DB_RESULT=`cat ${SQL_STAT}|grep ORA|head -1`
DB_CHECK=`cat ${SQL_STAT}|grep ORA|wc -l |awk '{print $1}'`

if [ ${DB_CHECK} -gt 0 ]
then
   echo "Oracle error"
   echo "${DB_RESULT}"
   rm ${SQL_LIST} ${SQL_STAT}
   exit
fi

echo "Date : ${INPUT_DATE}"
echo "Platform Result : ${INPUT_SERVICE}"

while read line
do
  ROW=`echo $line |awk -F '|' '{print $1}'`
  TOTAL=`echo $line |awk -F '|'  '{print $2}'`
  CODE=`echo $line |awk -F '|'  '{print $3}'`
  DESC=`echo $line |awk -F '|'  '{print $4}'`
  echo "[${ROW}] ${TOTAL}"
  echo "Error - ${CODE} : ${DESC}"
  echo ""
done < ${SQL_STAT}

rm ${SQL_LIST} ${SQL_STAT}
