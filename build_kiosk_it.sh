#! /bin/bash 

# Descr: Creation of Italian Kios Fedora spin (arch i686)
# Author: Francesco D'Aluisio <fdaluisio@fedoraproject.org>
# License: GPLv2


RUNDIR=`pwd`
KIOSKNAME="CHIOSCO-IT"
TMPDIR="${RUNDIR}/tmp/"
CACHEDIR="${RUNDIR}/cache/"
KSFILE="${RUNDIR}/kiosk-it.ks"


echo '##########################################################'
echo '#             Fedora Italian Kiosk Spin                  #'
echo '##########################################################'


if [ ! -e /usr/share/spin-kickstarts/fedora-live-base.ks ]; then
	echo "Please install fedora-kickstarts package"
	echo "# yum -y install fedora-kickstarts"
	exit -1
fi

if [ ! -d ${TMPDIR} ]; then
	mkdir ${TMPDIR}
fi

if [ ! -d ${CACHEDIR} ]; then
        mkdir ${CACHEDIR}
fi

if [ -x /usr/bin/livecd-creator ]; then
	echo "Require root password"
	su -c "nohup setarch i686 /usr/bin/livecd-creator -t ${TMPDIR} -f ${KIOSKNAME} -c ${KSFILE} --cache=${CACHEDIR} > ${KIOSKNAME}-`date +%d%M%Y`.log"
else
	echo "please install fedora livecd-tools packages"
fi
