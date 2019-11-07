#!/bin/ksh

filelist="listoffiles.dat"
csvlist="csvfiles.dat"
mergelist="mergelist.dat"
adlist="addslist.dat"

sudo rm -f *.csv

start=`date +%s`
while read line
do
        sudo wget -q $line
        listname=$(eval "echo "$line" | cut -f5 -d'/'")
        listsize=$(eval "wc -l $listname | cut -f1 -d' '")
        echo "$(tput setaf 3)[$listname]:$(tput sgr0) $(tput setaf 6)$listsize Addresses$(tput sgr0)"
done < "$filelist"
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Files Extracted]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
ls -ltr *.csv | awk '{print $9}' > csvfiles.dat
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Unique .CSV Names]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

x=1
start=`date +%s`
while read line
do
if [[ $x = 1 ]]
        then
                cat $line | sed '1d' > $mergelist
        else
                cat $line | sed '1d' >> $mergelist
fi
x=$((x+1))
done < "$csvlist"
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Merged .CSV Files]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
sudo arp-scan --retry=10 --ignoredups -I eth0 --localnet | head -n -3 | tail -n +3 | sed 's/[\t]/~/g' > $adlist
devcnt=$(eval "wc -l $adlist | cut -f1 -d' '")
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Arp-Scan Complete (Eth0)]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0) $(tput setaf 5)[$devcnt devices found]$(tput sgr0)"

a=1
start=`date +%s`
awk -F'~' '{print $2}' $adlist | cut -f1-3 -d':' | sed 's/://g' | tr '[:lower:]' '[:upper:]' | while read -r line; do
        cline=$(eval "sed "$a!d" $adlist")
        sudo sed -i "s/$cline/$cline~$line/" $adlist
a=$((a+1))
done
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Append Concat MAC Adrs]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

b=1
start=`date +%s`
cut -f4 -d'~' $adlist | while read -r line; do
        cline=$(eval "sed "$b!d" $adlist")
        ndev=$(eval "grep "$line" $mergelist | cut -f3 -d',' | sed 's/\"//g'")
        sudo sed -i "s/$cline/$cline~$ndev/" $adlist
b=$((b+1))
done
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Vendor Lookup Ref]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
diag="diagrpt.txt"
sudo touch $diag
sudo chmod 777 $diag
curl -s "http://192.168.86.1/api/v1/diagnostic-report" | gzip -d > $diag
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Diagnostic Complete]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
while read line
do
ipadd=$(eval "echo $line | cut -f1 -d'~'")
devid=$(eval "curl -s 'http://192.168.86.1/api/v1/get-shmac?ip=$ipadd' | sed '1d;3d' | sed 's/\"id\"://g;s/ //g;s/\"//g'")
sudo sed -i "s/$line/$line~$devid/" $adlist
done < "$adlist"
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Device ID Captured]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
while read line
do
sudo touch tempfile.txt
sudo chmod 777 tempfile.txt
devid=$(eval "echo $line | cut -f6 -d'~'")
grep -s -A 8 -a $'station_info {\n\t station_id: \"'$devid'\"' $diag | sed 's/--//g' | sed '/^[[:space:]]*$/d' |  grep -A 7 -a '\"'$devid'\"' | sed "s/[[:space:]]\+//g" > tempfile.txt
dhcp=$(eval "grep -s "dhcp_hostname" tempfile.txt | sed 's/dhcp_hostname://g;s/\"//g'")
sudo sed -i "s/$line/$line~$dhcp/" $adlist
done < "$adlist"
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Device Info Resolved]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

sudo sed -i "s/*/$/g;s/$.*/Unknown/g" $adlist

start=`date +%s`
while read line
do
sudo touch flatdiag.dat
sudo chmod 777 flatdiag.dat
devid=$(eval "echo $line | cut -f6 -d'~'")
if [[ "$devid" == "" || -z "$devid" ]] then
tstatus="0"
else
grep -A 35 -a $'station_state_update {\n\t station_info {\n\t station_id: \"123\"' $diag | sed 's/[[:space:]]//g' | sed 's/^}//g' | sed -e 's/^ //g' | sed 's/${//g' | sed ':a;$!N;s/^\s*\n\s*$//;ta;P;D' | head -n -21 | sed 'N;/.*{/!P;D' | sed '/^$/d' | sed 's/.*station_id.*/@@\n&/' | awk 'BEGIN {RS="@@"; FS="\n"; OFS="~"} NR>1 {$1=RS; NF--; print}' | sed 's/@@~//g' | grep "$devid" | awk -F"~" '{for(i=1;i<=NF;i++){if ($i ~ /last_seen_seconds_since_epoch:/){print $i}}}' > flatdiag.dat
tstatus=$(eval "sed 's/last_seen_seconds_since_epoch://g' flatdiag.dat")
fi
if [[ $tstatus = 0 ]] then
status="Online"
else
end=`date +%s`
rstatus=$(($end-$tstatus))
status=$(eval "echo $rstatus secs Offline")
fi
sudo sed -i "s/$line/$line~$status/" $adlist
done < "$adlist"
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Flatten Diagnostic]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

sudo sed -i '1s/^/IP Address~MAC Address~ARP Device Manufacturer~MAC Lookup Value~Vendor Name~Device ID~Hostname~Status\n/' $adlist
(head -n 1 $adlist && tail -n +2 $adlist | sort -k1 -V) > tempfile.txt
cat tempfile.txt > $adlist

start=`date +%s`
./convert.ksh $adlist
sudo sed -i 's/<td>Online<\/td>/<td bgcolor=\"green\">Online<\/td>/g' htmlfile.html
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Text -> HTML]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"

start=`date +%s`
timets=`date '+%D %r'`
mailx -a 'Content-Type: text/html' -r "Google Wifi Monitoring" -s "Device List - $timets" $1 < htmlfile.html
end=`date +%s`
runtime=$((end-start))
echo "$(tput setaf 2)[Email Processed]:$(tput sgr0) $(tput setaf 6)$runtime secs$(tput sgr0)"