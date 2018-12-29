DISTRO=$( cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos|nameyourdistro)' | uniq )
UNINS_MYSQL=$( yum list installed | grep mysql )
REQ_MYSQL_VER="5.7.0"
install_mysql()
{
        if [ $DISTRO == "centos" ]
        then
                echo "Detected Linux distribution: $DISTRO"
		echo "Installing MYSQL"
                sudo yum update -y
                sudo yum install redhat-lsb-core -y
                sudo yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm -y
                sudo yum update -y
                sudo yum install mysql-community-server -y
                systemctl start mysqld
                grep 'A temporary password' /var/log/mysqld.log |tail -1
                TEMP_PASSWD=$(awk 'NR==6{print $11}' /var/log/mysqld.log)
                echo $TEMP_PASSWD
                /usr/bin/mysql_secure_installation
        elif [ $DISTRO == "debian" ]
        then
                echo "Detected Linux distribution: $DISTRO"
                apt update
                apt install sudo -y
                sudo apt install lsb-release -y
                sudo apt install wget -y
                sudo apt install gnupg -y
                sudo wget https://dev.mysql.com/get/mysql-apt-config_0.8.9-1_all.deb
                sudo dpkg -i mysql-apt-config_0.8.9-1_all.deb
                sudo apt update
                sudo apt-get install mysql-community-server -y
                service mysql start
                /usr/bin/mysql_secure_installation
        fi
}

uninstall_mysql()
{
		yum autoremove $UNINS_MYSQL -y
}

update_mysql()
{		
		echo "Are you sure you want to update : Y/N"
		read confirmation
		echo $confirmation
		echo "you want to take backup of date stored in your dbms : Y/n"
		 read backup
		echo $backup
	        if [ "$confirmation" == "y" -a "$backup" == "y" ]
		then
			# Ask from user about location where to take backup of data
			echo "Please enter the PATH of directory where you wan't to take backup of data"
			read location
			echo $location
			cd $location
			echo "please enter the user of mysql database"
			read mysql_user
			echo "taking backup of data"
			echo "Please enter the backupfile name"
			read back_file_name
			mysqldump -u $mysql_user -p --routines --all-databases > $back_file_name.sql
			echo "Uninstalling MYSQL"
			uninstall_mysql
			echo "Installing MYSQL"
			install_mysql
			# Then restore the data from the directory
			mysql -u root -p $back_file_name < $back_file_name.sql
		elif [ "$CONFIRMATION" == "Y" -a "$backup" == "n" ]
		then 
			# Uninstall mysql
			uninstall_mysql
			# Install mysql
			install_mysql
		else
			echo "please enter valid input"
		fi
}
CHECK=$( type mysql >/dev/null 2>&1 && echo "MySQL present." || echo "MySQL not present." )
if [ "$CHECK" == "MySQL not present." ]
then
        install_mysql
fi
CURR_MYSQL_VER=$(mysql --version|awk '{ print $5 }'|awk -F\, '{ print $1 }')
if [ "$CHECK" == "MySQL present." -a "$(printf '%s\n' "$REQ_MYSQL_VER" "$CURR_MYSQL_VER" | sort -V | head -n1)" = $REQ_MYSQL_VER ]
then
        echo "MYSQL IS INSTALLED CURRENT VERION IS:" $CURR_MYSQL_VER
else
        echo "UPDATING MYSQL CURRENT VERSION $CURR_MYSQL_VER REQUIRED VERION IS $REQ_MYSQL_VER"
	    update_mysql
fi