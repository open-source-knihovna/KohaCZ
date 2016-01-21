#!/bin/bash
# Author: Jiří Kozlovský <mail@jkozlovsky.cz>
# KohaCZ community (Koha community from Czech Republic)

if [ ! checkPrerequisitiesInstalled ]; then
	# The only sudo commands needed here ..
	sudo apt-get install git maven openjdk-7-jdk tomcat8

	sudo chgrp "$USER" /opt
	sudo chmod g+w /opt

	sudo chgrp "$USER" /var/lib/tomcat8/webapps/
	sudo chmog g+w /var/lib/tomcat8/webapps/
fi

if [ ! checkPrerequisitiesInstalled ]; then
	echo "Exiting now due to unmet dependencies"
	exit 1;
fi

# From here it is sufficient to have non-root priviliges
init() {
	if [ -d /opt/xcncip2toolkit ]; then
		echo "Directory /opt/xcncip2toolkit already exists, do you wish to pull the recent version ?"
		read -e -p "This will delete all contents from that dir and replace with fresh installation! [y/N] " yn

		if [ "$yn" == "y" ]; then
			rm -rf /opt/xcncip2toolkit
			createRepo
		fi
	else
		createRepo
	fi

	setupConnectorSettings
	compileConnector

	createTomcatLink
}


checkPrerequisitiesInstalled() {
	if [ ! "$(which git)" ] || [ ! "$(which mvn)" ] || [ ! "$(which native2ascii)" ] || [ ! "$(dpkg -l | grep tomcat8)" ] || [ ! "$(dpkg -l | grep openjdk-7-jdk)" ]; then
		echo "You must have these executables within your PATH:"
		echo "git, mvn, native2ascii"
		echo
		echo "And have installed these packages: tomcat8, openjdk-7-jdk"
		echo
		echo "native2ascii is provided with the openjdk-7-jdk package"
		return false
	else
		return true
	fi
}

createRepo() {
	# Clone the repo ..
	cd /opt
	git clone https://github.com/eXtensibleCatalog/xcncip2toolkit.git

	# Compile the core ..
	cd /opt/xcncip2toolkit/core/trunk
	mvn install
	mvn install -Dmaven.test.skip
}

setupConnectorSettings() {
	cd /opt/xcncip2toolkit/connectors/koha/3.xx/trunk/web/src/main/resources/

	export LC_ALL=cs_CZ.UTF-8
	export LANGUAGE=cs_CZ.UTF-8
	export LANG=cs_CZ.UTF-8

	configTmp=toolkit.properties.tmp
	config=toolkit.properties

	# Check if the configuration already exists ..
	if [ -f $config ]; then
		echo
		read -e -p "Configuration $config already exists, do you wish to create new one ? [Y/n] " yn

		if [ "$yn" == "n" ]; then
			return 0;
		fi
	fi

	wget -qN https://github.com/eXtensibleCatalog/xcncip2toolkit/raw/master/dockerfile/connectors/koha/toolkit.properties.example
	# Create temporary configuration to change the default values at
	cp toolkit.properties.example $configTmp

	echo
	echo "Koha's configTmpuration is on schedule.."
	echo ""
	echo "Please note that toolkit's koha connector cannot work without access to intranet, thus it is needed to provide."
	echo ""
	read -e -p "Enter NCIP bot username: " adminName
	echo ""
	read -s -p "Enter NCIP bot password: " adminPass
	echo ""
	read -s -p "Confirm the password: " adminPass2
	echo ""
	while [ "$adminPass2" !=  "$adminPass" ]; do
		read -s -p "Passwords does not match, try again: " adminPass2
		echo ""
	done
	echo ""
	echo "Now enter the hostname of your OPAC ( e.g. https://188.166.14.82)"
	echo "Please include http:// OR https:// protocol specification!"
	echo ""
	read -e -p "Hostname of your Koha Intranet: " opac
	# Purge the char '/' at the end if any ..
	opac=$(echo $opac | sed 's_/$__g')
	echo ""
	read -e -p "Port of your intranet (probably 8080):" port
	echo ""
	read -e -p "Enter your library full address: " address
	echo ""
	read -e -p "Enter your library name: " libraryName
	echo ""
	read -e -p "Enter your SIGLA: " sigla
	echo ""
	read -e -p "Enter URL of your online registration form (optional): " registrationLink
	echo ""

	sed -i "s_LibraryAddressHere_$(echo $address)_g" $configTmp
	sed -i "s_LibraryNameHere_$(echo $libraryName)_g" $configTmp
	sed -i "s_LibrarySIGLAHere_$(echo $sigla)_g" $configTmp
	sed -i "s_LibraryRegistrationLinkHere_$(echo $registrationLink)_g" $configTmp
	sed -i "s_KohaIPHere_$(echo $opac)_g" $configTmp
	sed -i "s_KohaPortHere_$(echo $port)_g" $configTmp

	sed -i "s_IntranetAdministratorNameHere_$(echo $adminName)_g" $configTmp
	sed -i "s_IntranetAdministratorPassHere_$(echo $adminPass)_g" $configTmp

	native2ascii -encoding utf8 $configTmp $configTmp

	# Move the temp config to the real config
	mv $configTmp $config
}

compileConnector() {
	cd /opt/xcncip2toolkit/connectors/koha/3.xx/trunk
	git pull origin master
	mvn install -Dmaven.test.skip
}

createTomcatLink() {
	ln -s /opt/xcncip2toolkit/connectors/koha/3.xx/trunk/web/target/koha-web-0.0.1-SNAPSHOT.war /var/lib/tomcat8/webapps/koha-web.war
	if [ $? != 0 ]; then
		echo "Could not create symlink, you probably don't have permissions to do so .. please execute these commands before running this script again"
		echo "
	sudo chgrp $USER /var/lib/tomcat8/webapps/
	sudo chmog g+w /var/lib/tomcat8/webapps/"
		exit 1
	fi

	echo "Attempting to restart tomcat8 service .."
	sudo service tomcat8 restart

	if [ $? == 0 ]; then
		echo "You should be able to see the xcncip2toolkit running on your machine port 8080, try it out ! --> http://$(getIP):8080"
	else
		echo "Failed to restart tomcat8, you will probably not be able to have the xcncip2toolkit deployed properly so you could try it out .. please run this manually:"
		echo "sudo service tomcat8 restart"
		exit 1
	fi

}

getIP() {
	ip addr | grep "state UP" -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d/
}

init

exit 1
