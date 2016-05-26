#!/bin/bash

if [ $# -lt 1 ]; then
    echo "You have to specify version" 1>&2
    exit 1
fi

VERSION=$1
SERVER=192.168.1.113

msgcat misc/translator/po/cs-CZ-opac-bootstrap-orig.po misc/translator/po/cs-CZ-opac-bootstrap-kohacz.po > misc/translator/po/cs-CZ-opac-bootstrap.po
msgcat misc/translator/po/cs-CZ-staff-prog-orig.po misc/translator/po/cs-CZ-staff-prog-kohacz.po > misc/translator/po/cs-CZ-staff-prog.po
msgcat misc/translator/po/cs-CZ-pref-orig.po misc/translator/po/cs-CZ-pref-kohacz.po > misc/translator/po/cs-CZ-pref.po

DEB_BUILD_OPTIONS=nocheck ./debian/build-git-snapshot -r ~/debian -v $VERSION -d --noautoversion

scp "../debian/koha-deps_${VERSION}_all.deb" $SERVER:/root/kohadeb/
scp "../debian/koha-perldeps_${VERSION}_all.deb" $SERVER:/root/kohadeb/
scp "../debian/koha-common_${VERSION}_all.deb" $SERVER:/root/kohadeb/

ssh root@192.168.1.113 <<ENDSSH
    cd /root/
    aptly repo add kohacz kohadeb/koha-deps_${VERSION}_all.deb
    aptly repo add kohacz kohadeb/koha-perldeps_${VERSION}_all.deb
    aptly repo add kohacz kohadeb/koha-common_${VERSION}_all.deb
    aptly snapshot create $VERSION from repo kohacz
    aptly publish drop jessie
    aptly publish snapshot -architectures="i386,amd64" $VERSION
    cp -r .aptly/public/* /var/www/debian/
ENDSSH

rm misc/translator/po/cs-CZ-opac-bootstrap.po
rm misc/translator/po/cs-CZ-staff-prog.po
rm misc/translator/po/cs-CZ-pref.po

