#! /bin/bash 

# Descr: Creation of Italian Kios Fedora spin (arch i686)
# Author: Francesco D'Aluisio <fdaluisio@fedoraproject.org>
# License: GPLv2


RUNDIR=`pwd`
KIOSKNAME="CHIOSCO-IT"
TMPDIR="${RUNDIR}/tmp/"
CACHEDIR="${RUNDIR}/cache/"
KSFILE="${RUNDIR}/kiosk-it.ks"

if [ ! -e /usr/share/spin-kickstarts/fedora-live-base.ks ]; then
	echo "Please install fedora-kickstarts package"
	echo "# yum -y install fedora-kickstarts"
	exit -1
fi

if [ -x /usr/bin/livecd-creator ]; then
	#nohup "sudo setarch=i686 /usr/bin/livecd-creator -t ${TMPDIR} -f ${KIOSKNAME} -c ${KSFILE} --cache=${CACHEDIR}" > ${KIOSKNAME}-creation.log &
	echo "Require root password"
	su -c "nohup setarch=i686 /usr/bin/livecd-creator -t ${TMPDIR} -f ${KIOSKNAME} -c ${KSFILE} --cache=${CACHEDIR} > ${KIOSKNAME}-creation.log"
else
	echo "please install fedora livecd-tools packages"
fi
