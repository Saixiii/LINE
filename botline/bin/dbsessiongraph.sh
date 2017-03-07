#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           19/08/2015
##  Function:       Get oracle active session graph
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
PATH_IMAGE="${PATH_HOME}/image"
FILE_CONFIG="${PATH_CONFIG}/oracle.conf"
SQL_STAT="${PATH_LOG}/SQL_SESSION_DB.${PID_ID}"
SQL_CORE="${PATH_LOG}/SQL_LICENSE_DB.${PID_ID}"
SQL_STAT="${PATH_LOG}/SQL_SESSION_DB.${PID_ID}"
GNU_STAT="${PATH_LOG}/SQL_GNU_DB.${PID_ID}"
GNU_IMAGE="${PATH_IMAGE}/session.png"

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "em <Database> <Minute length>"
   printf "Require  : <Database> ["
   cat ${FILE_CONFIG} |awk -F, '{if(($2!="")&&($3!="")&&($4!="")) print $1}' |tr '\n' '|'
   echo "]"
   echo "Optional : <Minute length> [30-2000]"
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
if [ ${PROC_COUNT} -gt 3 ]
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
   export ORACLE_USER=$DB_USER
   export ORACLE_PASS=$DB_PASS
   export ORACLE_SID=$DB_TNS
}

#-------------------------------------------------------------------------------
# Function    : func_SQLLicense
# Description : SQL*PLUS Query data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLLicense() {
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF  > ${SQL_CORE}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
SELECT CPU_CORE_COUNT_CURRENT
FROM v\$license
WHERE rownum <2;
EOF
}

#-------------------------------------------------------------------------------
# Function    : func_SQLQuery
# Description : SQL*PLUS Query data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLQuery() {
   echo "Time,CPU-Cores,CPU,UserI/O,SystemI/O,Concurrency,Scheduler,Application,Commit,Configuration,Administrative,Network,Queueing,Cluster,Other" > ${SQL_STAT}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF  >> ${SQL_STAT}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
SELECT to_char(sample_time,'YYYYMMDDHH24MI')||',${CPU_CORE},'||
ROUND((cpu+bcpu)/60,2)     ||','||
ROUND(uio/60,2)            ||','||
ROUND(sio/60,2)            ||','||
ROUND(concurrency/60,2)    ||','||
ROUND(scheduler/60,2)      ||','||
ROUND(application/60,2)    ||','||
ROUND(COMMIT/60,2)         ||','||
ROUND(configuration/60,2)  ||','||
ROUND(administrative/60,2) ||','||
ROUND(network/60,2)        ||','||
ROUND(queueing/60,2)       ||','||
ROUND(clust/60,2)          ||','||
ROUND(other/60,2)
FROM (SELECT
TRUNC(sample_time,'MI') AS sample_time,
DECODE(session_state,'ON CPU',DECODE(session_type,'BACKGROUND','BCPU','ON CPU'), wait_class) AS wait_class
FROM v\$active_session_history
WHERE sample_time > sysdate - ${INPUT_INTERVAL}/1440
AND sample_time<=TRUNC(SYSDATE,'MI')) ash
PIVOT (COUNT(*) FOR wait_class IN ('ON CPU' AS cpu,'BCPU' AS bcpu,'Scheduler' AS scheduler,'User I/O' AS uio,'System I/O' AS sio,
'Concurrency' AS concurrency,'Application' AS application,'Commit' AS COMMIT,'Configuration' AS configuration,
'Administrative' AS administrative,'Network' AS network,'Queueing' AS queueing,'Cluster' AS clust,'Other' AS other))
ORDER BY sample_time;
EOF
}


#-------------------------------------------------------------------------------
# Function    : func_plot
# Description : GNUPLOT
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_Plot() {
   DT_START=`cat ${SQL_STAT} |grep -v Time |awk -F, '{print $1}' |sort |head -1`
   DT_END=`cat ${SQL_STAT} |grep -v Time |awk -F, '{print $1}' |sort |tail -1`
   Y2_MAX=`cat ${SQL_STAT}|awk '{print $4}'|sort -rn|head -1`
   #X_LABEL=`echo "${INPUT_LENGTH}/20"|bc`
   #POINTER=`echo "${INPUT_LENGTH}/25"|bc`
   echo "set title noenhanced \"Oracle Acitve Sessions : ${INPUT_DB} [ Date : ${DT_START} - ${DT_END} ]\"" > ${GNU_STAT}
   echo "set terminal pngcairo size 1000,500 enhanced font \"Helvetica,10\"" >> ${GNU_STAT}
   echo "set datafile separator \",\"" >> ${GNU_STAT}
   echo "set lmargin 8" >> ${GNU_STAT}
   echo "set style fill solid noborder" >> ${GNU_STAT}
   echo "set ylabel \"Active Sessions\"" >> ${GNU_STAT}
   echo "set xdata time" >> ${GNU_STAT}
   echo "set timefmt \"%Y%m%d%H%M\"" >> ${GNU_STAT}
   echo "set format x \"%H:%M\"" >> ${GNU_STAT}
   echo "set grid ytics lc rgb \"#000000\" lw 1 lt 0" >> ${GNU_STAT}
   echo "set grid xtics lc rgb \"#000000\" lw 1 lt 0" >> ${GNU_STAT}
   echo "set key reverse Left outside" >> ${GNU_STAT}
   echo "set border 0" >> ${GNU_STAT}
   echo "set boxwidth 2" >> ${GNU_STAT}
   echo "set output \"${GNU_IMAGE}\"" >> ${GNU_STAT}
   echo "" >> ${GNU_STAT}
   echo "plot for [i=15:3:-1] \"${SQL_STAT}\" using 1:(sum [col=3:i] column(col)) with filledcurves x1 title columnheader(i), \\" >> ${GNU_STAT}
   echo "'' using 1:2 t column(2) with line lt 0 lc rgb \"red\" lw 3" >> ${GNU_STAT}
   /usr/bin/gnuplot ${GNU_STAT}
}


#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

# Verify pending process
func_VerfiyOwnProcess

INPUT_DB=$1
INPUT_INTERVAL=$2


if [ -z "$1" ]
then
  func_Usage
fi

if [ -z "$2" ]
then
  INPUT_INTERVAL="60"
elif [ $2 -lt 30 ] || [ $2 -gt 2000 ]
then
  func_Usage
fi

COUNT_DB=`cat ${FILE_CONFIG} |awk -F, -v s="$INPUT_DB" '{IGNORECASE = 1;if(($1==s)&&($2!="")&&($3!="")&&($4!="")) print $0}'|wc -l`

if [ ${COUNT_DB} != "1" ]
then
  func_Usage
fi

DB_TNS=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_DB" '{IGNORECASE = 1;if($1==s) print $2}'`
DB_USER=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_DB" '{IGNORECASE = 1;if($1==s) print $3}'`
DB_PASS=`cat ${FILE_CONFIG}|awk -F, -v s="$INPUT_DB" '{IGNORECASE = 1;if($1==s) print $4}'`

# Export oracle environment
func_OracleEnv

# Query DB
func_SQLLicense

CPU_CORE=`cat ${SQL_CORE}|awk '{print $1}'`

# Query DB
func_SQLQuery

DB_QUEUE=`cat ${SQL_STAT}|wc -l|awk '{print $1}'`
DB_RESULT=`cat ${SQL_STAT}|grep ORA|head -1`
DB_CHECK=`cat ${SQL_STAT}|grep ORA|wc -l |awk '{print $1}'`

if [ ${DB_QUEUE} -lt 2 ]
then
   echo "Stat report did not found or wrong input"
   rm ${SQL_STAT} ${SQL_CORE}
   exit
elif [ ${DB_CHECK} -gt 0 ]
then
   echo "Oracle error"
   echo "${DB_RESULT}"
   rm ${SQL_STAT} ${SQL_CORE}
   exit
fi




func_Plot

echo "pic=${GNU_IMAGE}"

rm ${SQL_STAT} ${SQL_CORE} ${GNU_STAT}
