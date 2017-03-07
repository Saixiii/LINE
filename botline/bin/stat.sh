#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           15/07/2015
##  Function:       Get Stat STM for VAS
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
   echo "stat <Service> <Interval> <Date>"
   printf "Require  : <Service> ["
   cat ${SQL_LIST} |tr '\n' '|'
   echo "]"
   echo "Optional : <Interval Minute> [10-1440]"
   echo "         : <Date> [YYYYMMDD]"
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
PROC_COUNT=`ps -ef |grep $(basename $0) |egrep -v "grep|$$|vi" |awk '{print $2}' |wc -l|awk '{print $1}'`
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
   echo "Platform : ${INPUT_SERVICE}" > ${SQL_STAT} 
   echo "    Date     |  Rate   | Trx" >> ${SQL_STAT}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF  >> ${SQL_STAT}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
select to_char(grpd_dts,'Mon-DD HH24:MI')||' | '||round(nvl(success,0)/(nvl(success,0)+nvl(fail,0)+0.00001)*100,2)||'%'||' | '||(nvl(success,0)+nvl(fail,0))
from
(
select a.grpd_dts,sum(a.value) as val,nvl(b.type,1) as result
from (
select service_name,result_code,value,(date '1900-01-01' + floor(round(( end_date - date '1900-01-01' )*1440/ ${INPUT_INTERVAL}, 12))* ${INPUT_INTERVAL} /1440)  as grpd_dts
from report_data
where end_date >= to_date('${INPUT_DATE}0000','YYYYMMDDHH24MI')
and service_name = upper('${INPUT_SERVICE}')
) a
left join mapping_result b
on a.result_code = b.result_code
and a.service_name = b.service_name
group  by a.grpd_dts,b.type
)
pivot
(
sum(val)
for result in (0 as success,1 as fail)
)
order by grpd_dts;
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
   INPUT_DATE=`date +"%Y%m%d"`
fi


# Query USSD
func_SQLQuery
cat ${SQL_STAT}

rm ${SQL_LIST} ${SQL_STAT}
