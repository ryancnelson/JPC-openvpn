All: .apt-get-updated .openvpn-installed .bounce-things /root/openvpn/static.key /root/openvpn/server.conf .explain-things 

PUBIP = $(shell ifconfig eth0 | grep 'inet addr' | perl -pe 's/.*inet addr:(.*)  Bca.*/\1/' )
PRIVIP = $(shell ifconfig eth1 | grep 'inet addr' | perl -pe 's/.*inet addr:(.*)  Bca.*/\1/' )

clean:

realclean:
	make clean
	rm -f .openvpn-installed
	rm -f .apt-get-updated
	rm -f .ipv4-forwarding-on

/root/openvpn/static.key:
	@### yes, i know this is a really ugly hack
	@### it's only because often, the machine has *just*
	@### sprung into existence, and the keygen hangs.
	@dd if=/dev/urandom of=/dev/random bs=1024k count=20
	openvpn --genkey --secret /root/openvpn/static.key

.openvpn-installed:
	apt-get -y install openvpn && mkdir -p /root/openvpn && touch .openvpn-installed
	
/root/openvpn/server.conf:
	echo "dev tun" > /root/openvpn/server.conf
	echo "proto tcp-server" >> /root/openvpn/server.conf	
	echo "ifconfig 10.77.88.1 10.77.88.2" >> /root/openvpn/server.conf
	echo "secret /root/openvpn/static.key" >> /root/openvpn/server.conf	

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
	
.bounce-things:

