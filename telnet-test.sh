#!/bin/bash
##      telnet checker, log IP address and user:pass
## 		Disaclaimer - Use on local lan only, don't scan networks you don't own/have permission for!
##		example: [ bash telnet-test.sh 192.168.0.0/16 ]
clear

if [ -f ./open-telnet.txt ]; then
        rm ./open-telnet.txt
fi

if [ -f ./paused.conf ]; then
        rm ./paused.conf
fi

touch open-telnet.txt
masscan -p23 --open-only $1 --rate=5000 | sort -u > telnet.txt #save full list
cat telnet.txt | cut -d" " -f 6 | sort -u > ip.txt #clean up IP list
while read ip; do
{
#We use expect to login to telnet and check creds
/usr/bin/expect << EOF
## set these here before running script
set user admin
set pass admin
###		for expect debugging uncomment next line
#exp_internal 1 
set timeout -1
set ipaddr $ip
spawn telnet $ip
sleep 3
set timeout 3
expect -glob "*:*"
send -- "\$user\r"
sleep 3
#exp_internal 1
expect -glob "*assword*"
send -- "\$pass\r\n"
set timeout 3
sleep 3

expect -re {
	timeout { ### if timeout, log timeout
	set outputFilename "open-telnet.txt"
	set outFileId [open \$outputFilename "w"]
	puts -nonewline \$outFileId "\$ipaddr - Timed Out\n"
	close \$outFileId
	}
}

#exp_internal 1
	###if password found, we log good responses
expect -glob "*#" { 
	send -- "cd ../../../\r"
	sleep 2
	expect -glob "*#"
	send -- "ls\r"
	sleep 2
	expect -glob "*root*"
	send -- "exit\r"
	sleep 2
	expect -glob "*xi*"
	set outputFilename "open-telnet.txt"
	set outFileId [open \$outputFilename "w"]
	puts -nonewline \$outFileId "\$ipaddr - \$user:\$pass\n"
	close \$outFileId

} 

	###if no password found, we log bad responses
expect -glob "*assword\r*" {
	sleep 2
	set timeout 1
	send "\r\n\r\n\r\n"
	sleep 2
	set outputFilename "open-telnet.txt"
	set outFileId [open \$outputFilename "w"]
	puts -nonewline \$outFileId "\$ipaddr - bad password\n"
	close \$outFileId
}

EOF
}

done < ip.txt

cat open-telnet.txt
