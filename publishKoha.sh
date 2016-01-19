#!/bin/bash

if [ $# -lt 1 ]; then
    echo "You have to specify version" 1>&2
    exit 1
fi

VERSION=$1
SERVER=192.168.1.113


#DEB_BUILD_OPTIONS=nocheck ./debian/build-git-snapshot -r ~/debian -v $VERSION -d --noautoversion

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

