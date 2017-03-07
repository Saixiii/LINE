#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##  Date:           29/07/2015
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
PATH_IMAGE="${PATH_HOME}/image"
SQL_LIST="${PATH_LOG}/SQL_LIST_STM.${PID_ID}"
SQL_STAT="${PATH_LOG}/SQL_STAT_STM.${PID_ID}"
GNU_STAT="${PATH_LOG}/SQL_GNU_STM.${PID_ID}"
GNU_IMAGE="${PATH_IMAGE}/stat.png"

#-------------------------------------------------------------------------------
# Function    : func_Usage
# Description : Script usage
# Parameters  : <None>
# Return      : echo usage
#-------------------------------------------------------------------------------
func_Usage() {
   echo "stat <Service> <Interval> <Date> <X-Axis Length>"
   printf "Require  : <Service> ["
   cat ${SQL_LIST} |tr '\n' '|'
   echo "]"
   echo "Optional : <Interval Minute> [10-1440]"
   echo "         : <Date> [YYYYMMDD]"
   echo "         : <X-Axis Length> [60-200]"
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
   echo "Time %Success Transactions" > ${SQL_STAT}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF  >> ${SQL_STAT}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
select * from
(
select '"'||to_char(grpd_dts,'DD-Mon HH24:MI')||'" '||round(nvl(success,0)/(nvl(success,0)+nvl(fail,0)+0.000001)*100,2)||' '||(nvl(success,0)+nvl(fail,0))
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
order by grpd_dts
)
where rownum < ${INPUT_LENGTH};
EOF
}


#-------------------------------------------------------------------------------
# Function    : func_plot
# Description : GNUPLOT
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_Plot() {
   Y2_MAX=`cat ${SQL_STAT}|awk '{print $4}'|sort -rn|head -1`
   X_LABEL=`echo "${INPUT_LENGTH}/20"|bc`
   POINTER=`echo "${INPUT_LENGTH}/25"|bc`
   echo "set title noenhanced textcolor rgb \"yellow\" \"${INPUT_SERVICE} Success rate   [ Date : ${INPUT_DATE} - Interval : ${INPUT_INTERVAL} min ]\"" > ${GNU_STAT}
   echo "set terminal pngcairo size 900,500 enhanced font \"Helvetica,10\" background rgb \"#1E1E1E\"" >> ${GNU_STAT}
   echo "set style fill solid border lt -1" >> ${GNU_STAT}
   echo "set key off" >> ${GNU_STAT}
   echo "set style func linespoints" >> ${GNU_STAT}
   echo "set border 0" >> ${GNU_STAT}
   echo "set tics scale 0" >> ${GNU_STAT}
   echo "set lmargin 12" >> ${GNU_STAT}
   echo "set boxwidth 2" >> ${GNU_STAT}
   echo "set xtics textcolor rgb \"white\" " >> ${GNU_STAT}
   echo "set format y \"%.1f%%\";set ytics textcolor rgb \"yellow\" " >> ${GNU_STAT}
   echo "set y2tics textcolor rgb \"#2994FF\" " >> ${GNU_STAT}
   echo "set style line 1 lc rgb \"yellow\" lt 1 lw 2 pi -${POINTER} pt 6 ps 1" >> ${GNU_STAT}
   echo "set grid ytics lc rgb \"#CCFFFF\" lw 1 lt 0" >> ${GNU_STAT}
   echo "set y2range [0:$Y2_MAX*2]" >> ${GNU_STAT}
   echo "set ylabel \"% Success rate\" textcolor rgb \"yellow\"" >> ${GNU_STAT}
   echo "set y2label \"Transactions\" textcolor rgb \"#2994FF\"" >> ${GNU_STAT}
   echo "set xtics nomirror rotate 45 right" >> ${GNU_STAT}
   echo "set output \"${GNU_IMAGE}\"" >> ${GNU_STAT}
   echo "" >> ${GNU_STAT}
   echo "plot '${SQL_STAT}' using (\$3):xtic(int(\$0)%${X_LABEL}==1 ? strcol(1):'') t column(3) with histogram lc rgb \"#0075EB\" axes x1y2, \\" >> ${GNU_STAT}
   echo "'' using (\$2):xtic(int(\$0)%${X_LABEL}==1 ? strcol(1):'') t column(2) with lines ls 1 axes x1y1 \\" >> ${GNU_STAT}
   
   /usr/bin/gnuplot ${GNU_STAT}
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
INPUT_LENGTH=$4

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
   INTERVAL_DAY=`echo "${INPUT_INTERVAL}*48" |bc`
   INPUT_DATE=`date --date "-${INTERVAL_DAY} mins" +"%Y%m%d"`
fi

if [ -z "$4" ]
then
   INPUT_LENGTH="120"
elif [ $4 -lt 60 ] || [ $4 -gt 200 ]
then
   func_Usage
fi

if [ $2 -eq "10" ] && [ -z "$3" ]
then
   INPUT_DATE=`date +"%Y%m%d"`
   INPUT_LENGTH="150"
fi

# Query USSD
func_SQLQuery

DB_QUEUE=`cat ${SQL_STAT}|wc -l|awk '{print $1}'`
DB_RESULT=`cat ${SQL_STAT}|grep ORA|head -1`
DB_CHECK=`cat ${SQL_STAT}|grep ORA|wc -l |awk '{print $1}'`

if [ ${DB_QUEUE} -lt 2 ]
then
   echo "Stat report did not found or wrong input"
   rm ${SQL_LIST} ${SQL_STAT}
   exit
elif [ ${DB_CHECK} -gt 0 ]
then
   echo "Oracle error"
   echo "${DB_RESULT}"
   rm ${SQL_LIST} ${SQL_STAT}
   exit
fi




func_Plot

echo "pic=${GNU_IMAGE}"

rm ${SQL_LIST} ${SQL_STAT} ${GNU_STAT}
