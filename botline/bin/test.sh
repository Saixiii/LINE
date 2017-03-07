sudo -u ssoadmin /home/ssoadmin/script/get_sso_for_ccp.sh $1 > /tmp/sso.txt
tail -2 /tmp/sso.txt
rm /tmp/sso.txt
