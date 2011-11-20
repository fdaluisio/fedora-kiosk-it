# Maintained by the Dan Walsh and Miroslav Grepl
# http://people.fedoraproject.org/dwalsh/SELinux
# mailto:dwalsh@redhat.com
# mailto:mgrepl@redhat.com


# we use other fedora-* .ks files which are available from spin-kickstarts package

#%include fedora-livecd-desktop.ks
#%include fedora-live-desktop.ks

#%include fedora-live-minimization.ks
#%include fedora-live-base.ks

%include /usr/share/spin-kickstarts/fedora-live-minimization.ks
%include /usr/share/spin-kickstarts/fedora-live-base.ks

#repo --name=local --baseurl=file:///mnt/cdrom/
lang it_IT.UTF-8
keyboard it
timezone Europe/Rome

part / --size=8192

bootloader --timeout=1 

%packages
xguest
policycoreutils

@office
@gnome-desktop
@graphical-internet

# Add language groups
#@*-support


# remove tools which are not necessary/remove apps from main menu
-setroubleshoot*
-abrt*
-tiger*
-brasero*
-sound-juicer
-gthumb
-desktop-backgrounds*
-shotwell
-planner
-evolution*
#-rhythmbox
-cheese
-duplicity
-seahorse
-transmission*
-vinagre
-pino*

# help and art can be big, too
-gnome-user-docs
-evolution-help
-gnome-games-help
-desktop-backgrounds-basic
-*backgrounds-extras

# Drop things that pull in perl
-linux-atm

# No printing
-foomatic-db-ppds
-foomatic

# Dictionaries are big
-aspell-*
-hunspell-*
-man-pages*
-words

# Legacy cmdline things we don't want
-krb5-auth-dialog
-krb5-workstation
-pam_krb5
-quota
-nano
-minicom
-dos2unix
-finger
-ftp
-jwhois
-mtr
-pinfo
-rsh
-telnet
-nfs-utils
-ypbind
-yp-tools
-rpcbind
-acpid
-ntsysv

# admin stuff
-openssh*
-sudo
-authconfig
-system-config-boot
-system-config-language
-system-config-network*
-system-config-network
-system-config-printer
-system-config-rootpassword
-system-config-services
-system-config-users
-policycoreutils-gui

# to make our iptables rules working
-anaconda
-system-config-firewall-base
-system-config-firewall*

# remove gnome stuff
-gnome-backgrounds
-gnome-disk-utility
-gnome-packagekit
-gnome-system-monitor
-gnome-games
-gnome-utils
-firstboot
-deja-dup

# remove groups (not sure why but it does not work)
-@sound-and-video
-@admin-tools
-@system-tools
-@dial-up
-@hardware-support
-@printing

# other remove
-autocorr-*
autocorr-it
autocorr-en

%end

%post

# create secmark.te policy file
cat > secmark.te << EOF

policy_module(secmark, 1.0)

# Type Definitions

require {
 type xguest_t;
 type avahi_t;
 attribute domain;
}

attribute external_packet;
type internal_packet_t;
corenet_packet(internal_packet_t)

type dns_external_packet_t, external_packet;
corenet_packet(dns_external_packet_t)

type http_external_packet_t, external_packet;
corenet_packet(http_external_packet_t)

type external_packet_t, external_packet;
corenet_packet(external_packet_t)

# Local Policy

allow domain internal_packet_t:packet { recv send };
allow avahi_t internal_packet_t:packet { recv send };

# COMMENT JUST FOR TESTING
allow xguest_t dns_external_packet_t:packet { recv send };
allow xguest_t http_external_packet_t:packet { recv send };

EOF

# compiling, installing secmark.pp policy module and removing policies files
[ -x /usr/bin/make ] && /usr/bin/make -f /usr/share/selinux/devel/Makefile
[ -x /usr/sbin/semodule ] && /usr/sbin/semodule -i secmark.pp
[ -x /bin/rm ] && /bin/rm secmark.te secmark.fc secmark.if secmark.pp 2> /dev/null

# COMMENT JUST FOR TESTING
#[ -x /usr/sbin/semodule ] && /usr/sbin/semodule -d unconfined
[ -x /usr/sbin/semodule ] && /usr/sbin/semodule -d unlabelednet

# COMMENT JUST FOR TESTING
rm -f /etc/init.d/livesys-adduser 
passwd -l root

# it shouldn't be needed since anaconda and s-c-firewall-base are not isntalled in kiosk
if [ -e /etc/sysconfig/iptables ];then
	mv /etc/sysconfig/iptables /etc/sysconfig/iptables.orig
fi

# we need to revert changes created by the fedora-live-base.ks file
# we only want to have SELinux kiosk user
cat >> /etc/rc.d/init.d/livesys << EOF

# COMMENT JUST FOR TESTING
[ -x /usr/sbin/userdel ] && /usr/sbin/userdel -r liveuser

# gnome stuff

# hide fallback-warning
cat >> /usr/share/glib-2.0/schemas/org.gnome.SessionManager.gschema.override << FOE
[org.gnome.SessionManager]
show-fallback-warning=false
FOE

cat >> /usr/share/glib-2.0/schemas/org.gnome.desktop.screensaver.gschema.override << FOE
[org.gnome.desktop.screensaver]
lock-enabled=false
FOE

# and hide the lock screen option
cat >> /usr/share/glib-2.0/schemas/org.gnome.desktop.lockdown.gschema.override << FOE
[org.gnome.desktop.lockdown]
disable-lock-screen=true
FOE

# disable updates plugin
cat >> /usr/share/glib-2.0/schemas/org.gnome.settings-daemon.plugins.updates.gschema.override << FOE
[org.gnome.settings-daemon.plugins.updates]
active=false
FOE

# set up auto-login to false
cat >> /etc/gdm/custom.conf << FOE
[daemon]
AutomaticLoginEnable=False
FOE

# iface=route |grep default |awk '{ print $8 }'

# base firewall

# DOS protection
[ -x /bin/echo ] && /bin/echo "1" > /proc/sys/net/ipv4/tcp_syncookies 2> /dev/null

[ -x /sbin/iptables ] && /sbin/iptables -N syn_flood
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -p tcp --syn -j syn_flood
[ -x /sbin/iptables ] && /sbin/iptables -A syn_flood -m limit --limit 1/s --limit-burst 5 -j RETURN
[ -x /sbin/iptables ] && /sbin/iptables -A syn_flood -j DROP

[ -x /sbin/iptables ] && /sbin/iptables -P INPUT DROP 
[ -x /sbin/iptables ] && /sbin/iptables -P FORWARD DROP 
[ -x /sbin/iptables ] && /sbin/iptables -P OUTPUT ACCEPT

[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

[ -x /sbin/iptables ] && /sbin/iptables -N http_traffic
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -p TCP -j http_traffic
[ -x /sbin/iptables ] && /sbin/iptables -A http_traffic -p TCP --dport 80 -j ACCEPT
[ -x /sbin/iptables ] && /sbin/iptables -A http_traffic -p TCP --dport 443 -j ACCEPT

[ -x /sbin/iptables ] && /sbin/iptables -N dns_traffic
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -p TCP -j dns_traffic
[ -x /sbin/iptables ] && /sbin/iptables -A dns_traffic -p TCP --dport 53 -j ACCEPT
[ -x /sbin/iptables ] && /sbin/iptables -A dns_traffic -p TCP --sport 53 -j ACCEPT


# SELINUX AND IPTABLES
# 
# http://www.linux.com/learn/tutorials/421152-using-selinux-and-iptables-together

[ -x /sbin/iptables ] && /sbin/iptables -F -t security
[ -x /sbin/iptables ] && /sbin/iptables -t security -A INPUT -m state --state ESTABLISHED,RELATED -j CONNSECMARK --restore
[ -x /sbin/iptables ] && /sbin/iptables -t security -A OUTPUT -m state --state ESTABLISHED,RELATED -j CONNSECMARK --restore

[ -x /sbin/iptables ] && /sbin/iptables -t security -X INTERNAL 2> /dev/null
[ -x /sbin/iptables ] && /sbin/iptables -t security -N INTERNAL


[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -d 255.255.255.255,127/8,10.0.0.0/8,172.16.0.0/16,224/24,192.168/16 -j INTERNAL
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -s 255.255.255.255,127/8,10.0.0.0/8,172.16.0.0/16,224/24,192.168/16 -j INTERNAL

[ -x /sbin/iptables ] && /sbin/iptables -t security -A INTERNAL -j SECMARK --selctx system_u:object_r:internal_packet_t:s0
[ -x /sbin/iptables ] && /sbin/iptables -t security -A INTERNAL -j CONNSECMARK --save
[ -x /sbin/iptables ] && /sbin/iptables -t security -A INTERNAL -j ACCEPT

[ -x /sbin/iptables ] && /sbin/iptables -t security -X DNS 2> /dev/null
[ -x /sbin/iptables ] && /sbin/iptables -t security -N DNS

[ -x /sbin/iptables ] && /sbin/iptables -t security -X HTTP 2> /dev/null
[ -x /sbin/iptables ] && /sbin/iptables -t security -N HTTP

# we want to allow only this traffic from/to external network

[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -p udp --dport 53 -j DNS
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -p udp --sport 53 -j DNS
[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -p tcp --dport 53 -j DNS
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -p tcp --sport 53 -j DNS

[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -p tcp --dport 80 -j HTTP
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -p tcp --sport 80 -j HTTP
[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -p tcp --dport 443 -j HTTP
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -p tcp --sport 443 -j HTTP

[ -x /sbin/iptables ] && /sbin/iptables -t security -A DNS -j SECMARK --selctx system_u:object_r:dns_external_packet_t:s0
[ -x /sbin/iptables ] && /sbin/iptables -t security -A DNS -j CONNSECMARK --save
[ -x /sbin/iptables ] && /sbin/iptables -t security -A DNS -j ACCEPT

[ -x /sbin/iptables ] && /sbin/iptables -t security -A HTTP -j SECMARK --selctx system_u:object_r:http_external_packet_t:s0
[ -x /sbin/iptables ] && /sbin/iptables -t security -A HTTP -j CONNSECMARK --save
[ -x /sbin/iptables ] && /sbin/iptables -t security -A HTTP -j ACCEPT


[ -x /sbin/iptables ] && /sbin/iptables -t security -X EXTERNAL 2> /dev/null
[ -x /sbin/iptables ] && /sbin/iptables -t security -N EXTERNAL

[ -x /sbin/iptables ] && /sbin/iptables -A OUTPUT -t security -j EXTERNAL
[ -x /sbin/iptables ] && /sbin/iptables -A INPUT -t security -j EXTERNAL

[ -x /sbin/iptables ] && /sbin/iptables -t security -A EXTERNAL -j SECMARK --selctx system_u:object_r:external_packet_t:s0
[ -x /sbin/iptables ] && /sbin/iptables -t security -A EXTERNAL -j CONNSECMARK --save
[ -x /sbin/iptables ] && /sbin/iptables -t security -A EXTERNAL -j ACCEPT


[ -x /sbin/ip6tables ] && /sbin/ip6tables -F -t security
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A INPUT -m state --state ESTABLISHED,RELATED -j CONNSECMARK --restore
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A OUTPUT -m state --state ESTABLISHED,RELATED -j CONNSECMARK --restore

[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -X INTERNAL 2> /dev/null
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -N INTERNAL

[ -x /sbin/ip6tables ] && /sbin/ip6tables -A OUTPUT -t security -d FEC0::/10,::1/128,FF::/8,FE80::/10,FC00::/7 -j INTERNAL
[ -x /sbin/ip6tables ] && /sbin/ip6tables -A INPUT -t security -s FEC0::/10,::1/128,FF::/8,FE80::/10,FC00::/7 -j INTERNAL

[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A INTERNAL -j SECMARK --selctx system_u:object_r:internal_packet_t:s0
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A INTERNAL -j CONNSECMARK --save
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A INTERNAL -j ACCEPT

[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -X EXTERNAL 2> /dev/null
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -N EXTERNAL

[ -x /sbin/ip6tables ] && /sbin/ip6tables -A OUTPUT -t security -j EXTERNAL
[ -x /sbin/ip6tables ] && /sbin/ip6tables -A INPUT -t security -j EXTERNAL

[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A EXTERNAL -j SECMARK --selctx system_u:object_r:external_packet_t:s0
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A EXTERNAL -j CONNSECMARK --save
[ -x /sbin/ip6tables ] && /sbin/ip6tables -t security -A EXTERNAL -j ACCEPT

EOF

%end
