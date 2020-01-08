# GWifi

`convert.ksh`

This file will be used to convert the values generated from the getfiles.ksh script into an html readable format so that when it is sent to the users email it will be tabelized for easier viewing.

`getfiles.ksh`

This will pull in the different master lists from different MAC Vendors to try and match up the MAC Address with a valid manufacturer that made the device. It will also parse through the diganostic report that it will curl down onto the server and extract each of the different devices that are currently connected to your network through the GWifi network. Most of the devices it should pull in the actual device name that it is labeled within the network, but sometimes it won't correctly pull it or the device name isn't being populated within the diagnostic report. It will also show if the current device is connected to the network or not, if it isn't connected it will show the last time that it connected to the network. It will also give each of the different IP Addresses that are being currently used within the network in a descending order.

Below is an example of what the output will look like when you receive it in an email:

IP Address | MAC Address | ARP Device Manufacturer | MAC Lookup Value | Vendor Name | Device ID |	Hostname | Status
------------ | ------------- | ------------- | ------------- | ------------- | ------------- | ------------- | -------------
192.168.86.1 | d8:6c:63:da:63:15 | (Unknown) | D86C63 | Google | | | Online

When you are running the script from the command line you will want to pass in your email address that you are wanting to send the results to:

`./getfiles.ksh aaaa@gmail.com`

```shell
mailx -a 'Content-Type: text/html' -r "Google Wifi Monitoring" -s "Device List - $timets" $1 < htmlfile.html
```

*The only feature that I did not add to the wrapper script was the ability to be a cron job/watcher job whenever the device list increased from the previous amount and that could be based on any time interval when checking, that is really up to the user. This can easily be added by someone else to improve this script, any other improvements that you see fit for this script go right on ahead and make it better!*
