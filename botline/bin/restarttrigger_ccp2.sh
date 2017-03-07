echo "Restart jobservices on 10.80.247.8"
ssh cdr@10.80.247.8 /home/cdr/INOPS/UTIL/restart_jobservices.sh
echo "Restart jobservices on 10.80.247.9"
ssh cdr@10.80.247.9 /home/cdr/INOPS/UTIL/restart_jobservices.sh
