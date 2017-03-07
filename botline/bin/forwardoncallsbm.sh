#!/usr/bin/sh
##===============================================================================##
##  Author:         Thanaroj Ratanamungmeka [KLa] 
##  Date:           10/09/2014
##  Function:       Check Dest
##===============================================================================##
. /home/mstm/.bash_profile

msisdn="$1"

if [ -z "$1" ]
then
   echo "Number 66xxxxxxx"
   exit
fi


msisdn=`cat /home/mstm/KLA/LINEBOT/FWONCALL/member.conf | grep -i $1 | awk -F"|" '{print $1}'`
names=`cat /home/mstm/KLA/LINEBOT/FWONCALL/member.conf | grep -i $1 | awk -F"|" '{print $3}'`
cd /home/mstm/KLA/LINEBOT/FWONCALL
./addCallForward_rhlr_msisdn.sh $msisdn  
echo "Now oncall is : K.$names" 
