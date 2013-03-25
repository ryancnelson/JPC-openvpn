All: .apt-get-updated .openvpn-installed /root/openvpn/static.key /etc/openvpn/joyentcloud.conf /root/openvpn/openvpn-client.conf /etc/default/openvpn .explain-things .bounce-things

PUBIP = $(shell ifconfig eth0 | grep 'inet addr' | perl -pe 's/.*inet addr:(.*)  Bca.*/\1/' )
PRIVIP = $(shell ifconfig eth1 | grep 'inet addr' | perl -pe 's/.*inet addr:(.*)  Bca.*/\1/' )

clean:

realclean:
	make clean
	rm -f .openvpn-installed
	rm -f .apt-get-updated
	rm -f .ipv4-forwarding-on

/etc/default/openvpn:
	grep joyentcloud /etc/default/openvpn || echo AUTOSTART=\"joyentcloud\" >> /etc/default/openvpn 

/root/openvpn/openvpn-client.conf:
	echo remote $(PUBIP) > /root/openvpn/openvpn-client.conf
	echo dev tun >> /root/openvpn/openvpn-client.conf
	echo proto tcp-client >> /root/openvpn/openvpn-client.conf
	echo ifconfig 10.77.88.2 10.77.88.1  >> /root/openvpn/openvpn-client.conf
	echo secret /root/openvpn/static.key >> /root/openvpn/openvpn-client.conf

/root/openvpn/static.key:
	@### yes, i know this is a really ugly hack
	@### it's only because often, the machine has *just*
	@### sprung into existence, and the keygen hangs
	@### due to low-entropy on /dev/random
	@dd if=/dev/urandom of=/dev/random bs=1024k count=20
	openvpn --genkey --secret /root/openvpn/static.key

.openvpn-installed:
	apt-get -y install openvpn && mkdir -p /root/openvpn && touch .openvpn-installed
	
/etc/openvpn/joyentcloud.conf:
	echo "dev tun" > /etc/openvpn/joyentcloud.conf
	echo "proto tcp-server" >> /etc/openvpn/joyentcloud.conf
	echo "ifconfig 10.77.88.1 10.77.88.2" >> /etc/openvpn/joyentcloud.conf
	echo "secret /root/openvpn/static.key" >> /etc/openvpn/joyentcloud.conf

.ipv4-forwarding-on:
	echo 1 > /proc/sys/net/ipv4/ip_forward
	touch .ipv4-forwarding-on:

.outbound-SNAT-on:
	@iptables -L -t nat | grep SNAT || iptables -t nat -I POSTROUTING -o eth0 -j SNAT --to $(PUBIP) 
	touch .outbound-SNAT-on
	
.sh-is-bash:
	[ -f /bin/bash ] &&  ls -la /bin/sh | grep dash && ln -s /bin/bash /bin/sh.new && mv /bin/sh.new /bin/sh || echo "/bin/sh is not apparently a link to /bin/dash"
	ls -la /bin/sh | grep bash && touch .sh-is-bash

.apt-get-updated:
	apt-get update && touch .apt-get-updated

.explain-things:
	@echo ; echo ; echo
	@echo "Your Public IP address is $(PUBIP). Use that as your Server Address."
	@make /root/openvpn/openvpn-client.conf && echo && echo "Your openvpn client configuration file is at /root/openvpn/openvpn-client.conf ."  && echo "Copy that file to your client host, and run \"openvpn --config /path/to/openvpn-client.conf"
	@ echo ; echo ; echo
	@ echo "put this in /root/openvpn/static.key:" ; echo 
	@cat /root/openvpn/static.key	

.bounce-things:
	cd /root/openvpn
	/etc/init.d/openvpn stop
	sleep 3
	/etc/init.d/openvpn start

