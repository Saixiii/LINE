#!/usr/bin/sh

##===============================================================================##
##  Author:         Suphakit Annoppornchai [Bank]
##							Wissarut Wewek [Champ]
##  Date:           02/03/2016
##  Function:       Get CCP Trigger queue
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
echo "จะUnblock Event ไหนบ้าง"
echo "--------------------------------------------"
echo "Example"
echo "@sbm run CCP8_TRIGGER_BLOCK 1001,1002,1003,...,100x"
echo "--------------------------------------------"
echo "1001,Valid->Active(G|A)"
echo "1002,Active->OneWayBlock(A|D)"
echo "1003,OneWayBlock->TwoWayBlock(D|E)"
echo "1004,OneWayBlock->Active(D|A)"
echo "1005,TwoWayBlock->Active(E|A)"
echo "1006,TwoWayBlock->Termination(E|B)"
echo "1007,Valid->Termination(G|B)"
echo "1100,Add individual price plan"
echo "1101,Remove individual price plan"
echo "1102,Replace default price plan"
echo "1200,Top-up"
echo "1300,Balance Thereshold2"
echo "1400,Counter Threshold"
echo "1500,Recurring Status"
echo "1600,language change"
echo "1700,Data first use"
echo "1800,Reverse"
echo "1900,Deduct"
echo "2000,Refund"
echo "2100,BC Change"

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
   export ORACLE_USER=cc
   export ORACLE_PASS=zte78smart
   export ORACLE_SID=CCP7_CC
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
   echo "CCP8_TRIGGER_QUEUE" > ${SQL_QUEUE}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF |awk '{print $0}' >> ${SQL_QUEUE}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
update gw_trigger_config
set target_sys_id='1',retry_times='3'
where event_type in ${DB_TABLE};
commit;
update gw_trigger_instance
set fail_times='0',state='A'
where state ='E';
commit;
EOF
}

#-------------------------------------------------------------------------------
# Function    : func_SQLQuery
# Description : SQL*PLUS Query data
# Parameters  : <None>
# Return      : <None>
#-------------------------------------------------------------------------------
func_SQLQuery2() {
   echo "CCP8_TRIGGER_Status" > ${SQL_QUEUE}
   sqlplus -s "$ORACLE_USER/$ORACLE_PASS@$ORACLE_SID" << EOF |awk '{print $0}' >> ${SQL_QUEUE}
   SET ECHO OFF
   SET FEEDBACK OFF
   SET HEADING OFF
   SET PAGES 0
   SET TRIMS ON
   SET LINESIZE 9999
select 'Event Type : '|| trim(event_type)||' = '||trim(state) ||','||trim(target_sys_id)||','||trim(retry_times) from gw_trigger_config
order by event_type;
EOF
}

#-------------------------------------------------------------------------------
#     M A I N    P R O G R A M
#-------------------------------------------------------------------------------

# Verify pending process
func_VerfiyOwnProcess

# Export oracle environment
func_OracleEnv

if [ -z "$1" ]
then
  func_Usage
fi

# Query USSD
func_SQLQuery 
echo "### SQL ###"
DB_TABLE=$(echo "$1" |awk -F"," '{gsub(/\,/,"\x27,\x27",$0);print "(\x27"$0"\x27)"}')
echo "update gw_trigger_config
set target_sys_id='1',retry_times='3'
where event_type in ${DB_TABLE};"
echo "###########"

func_SQLQuery
func_SQLQuery2

cat ${SQL_QUEUE}

rm ${SQL_QUEUE}
