#!/usr/bin/env bash
echo 
echo "  ---------------------------------------"
echo "   PHPIPAM Automatic install on debian 9 "
echo "  ---------------------------------------"
echo "   sebastien@sebisme.be                  "
echo "  ---------------------------------------"
echo

# Must be run as root ! 
if [ "$EUID" -ne 0 ]
then
	echo "Please run this script as root !"
	exit 1
fi

LOG_FILE="/tmp/ipam_install.log"
ERROR_FILE="/tmp/ipam_install_error.log"
touch ${LOG_FILE}
touch ${ERROR_FILE}

ipam_admin_email="me@mydomain.org"             # PHPIPAM ADMIN EMAIL
ipam_admin_pass="myipampassword"               # PHPIPAM ADMIN PASSWORD

ipam_site_title="My Own Super PHPIPAM"         # PHPIPAM SITE TITLE
ipam_site_domain="mydomain.org"                # PHPIPAM SITE DOMAIN NAME
ipam_site_host="myipam"                        # PHPIPAM SITE HOST NAME
ipam_site_url_scheme="https"                   # PHP IPAM URL SCHEME (http or https)

ipam_site_url="${ipam_site_url_scheme}://${ipam_site_host}.${ipam_site_domain}"

ipam_parentpath="/var/www/"                    # PHPIPAM PARENT DIRECTORY PATH
ipam_dirname="ipam"                            # PHPIPAM DIRECTORY
ipam_dirpath=${ipam_parentpath}${ipam_dirname}

vhost_servername="${ipam_site_host}.${ipam_site_domain}"
vhost_ssl_servername="${ipam_site_host}.${ipam_site_domain}"
vhost_admin="me@mydomain.org"                   # PHPIPAM APACHE VHOST ADMIN
vhost_aliases="ipam.dom1.com ipam.dom2.org"     # PHPIPAM APACHE VHOST ALIASES
vhost_error_log="ipam_error.log"                # PHPIPAM APACHE VHOST ERROR LOG NAME
vhost_access_log="ipam_access.log"              # PHPIPAM APACHE VHOST ACCESS LOG NAME
vhost_ssl_error_log="ipam_ssl_error.log"        # PHPIPAM APACHE SSL VHOST ERROR LOG NAME
vhost_ssl_access_log="ipam_ssl_access.log"      # PHPIPAM APACHE SSL VHOST ACCESS LOG NAME

apache_conf_path="/etc/apache2/sites-available" # PHPIPAM APACHE VHOST CONFIG PATH
apache_vhost_ipam="ipam"                        # PHPIPAM APACHE VHOST NAME
apache_conf_ipam="${apache_vhost_ipam}.conf"
apache_vhost_ipam_ssl="ipam-ssl"                # PHPIPAM APACHE SSL VHOST NAME
apache_conf_ipam_ssl="${apache_vhost_ipam_ssl}.conf"

php_ipam_version="1.4"                          # PHPIPAM VERSION

sql_root_pwd="SQL@ROOTP4RD"                     # MySQL (mariadb) ROOT PASSWORD

sql_ipam_user="myipam-sql-user"                 # MySQL (mariadb) PHPIPAM USER
sql_ipam_pwd="myipam-secret-pass"               # MySQL (mariadb) PHPIPAM USER PASSWORD
sql_ipam_db="ipam"                              # MySQL (mariadb) PHPIPAM DB NAME

# Install all required packages
INSTALL_1=$(apt-get install -y mariadb-client mariadb-server >>${LOG_FILE} 2>>${ERROR_FILE})
IR1=$?
INSTALL_2=$(apt-get install -y expect >>${LOG_FILE} 2>>${ERROR_FILE})
IR2=$?
INSTALL_3=$(apt-get install -y jq snmp snmpd fping >>${LOG_FILE} 2>>${ERROR_FILE})
IR3=$?
if [[ "${IR1}" -eq "0" && "${IR2}" -eq "0" && "${IR3}" -eq "0" ]]
then
	echo "mariadb-server, mariadb-client, expect, jq, fping, and snmp are both succefully installed"
else
	echo "apt-get install was not possible. Please check log and error files (${LOG_FILE} and ${ERROR_FILE})"
	exit 1
fi
# Execute mysql_secure_installation with exoect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"${sql_root_pwd}\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "${SECURE_MYSQL}" >>${LOG_FILE}
echo "Mysql root password : ${sql_root_pwd}" >>${LOG_FILE}

INSTALL_4=$(apt-get install -y apache2 openssl >>${LOG_FILE} 2>>${ERROR_FILE})
IR4=$?
INSTALL_5=$(apt-get install -y php7.0 php7.0-zip php7.0-xmlrpc php7.0-xml php7.0-tidy php7.0-soap php7.0-snmp php7.0-mysql php7.0-mcrypt php7.0-mbstring php7.0-ldap php7.0-imap php7.0-gmp php7.0-gd php7.0-curl php7.0-bcmath php7.0-bz2 php-pear libapache2-mod-php7.0 >>${LOG_FILE} 2>>${ERROR_FILE})
IR5=$?
INSTALL_6=$(apt-get install -y git >>${LOG_FILE} 2>>${ERROR_FILE})
IR6=$?
INSTALL_7=$(apt-get install -y vim vim-pathogen >>${LOG_FILE} 2>>${ERROR_FILE})
IR7=$?
INSTALL_8=$(apt-get install -y netcat tcpdump dnsutils >>${LOG_FILE} 2>>${ERROR_FILE})
IR7=$?
if [[ "${IR4}" -eq "0" && "${IR5}" -eq "0" && "${IR6}" -eq "0" && "${IR7}" -eq "0" && "${IR8}" -eq "0" ]]
then
	echo "apache2, openssl, all required php package, git, vim, and vim-pathogen are both succefully installed"
else
	echo "apt-get install was not possible. Please check log and error files (${LOG_FILE} and ${ERROR_FILE})"
	exit 1
fi

# Create ipam directory and apache config
if [ -d "${apache_conf_path}" ]
then
	touch ${apache_conf_path}/${apache_conf_ipam}
	touch ${apache_conf_path}/${apache_conf_ipam_ssl}
fi

if [ -e "${apache_conf_path}/${apache_conf_ipam}" ]
then
	cat <<- EOF > ${apache_conf_path}/${apache_conf_ipam}
	<VirtualHost *:80>
        ServerAdmin ${vhost_admin}
        DocumentRoot ${ipam_dirpath}

        ServerName ${vhost_ssl_servername}
        ServerAlias ${vhost_aliases}
        <Directory ${ipam_dirpath}>
                Options FollowSymLinks
                AllowOverride all
                Order allow,deny
                Allow from all
        </Directory>
        ErrorLog \${APACHE_LOG_DIR}/${vhost_error_log}
        CustomLog \${APACHE_LOG_DIR}/${vhost_access_log} combined
	</VirtualHost>
	EOF
	echo "apache2 conf file created : ${apache_conf_path}/${apache_conf_ipam}" >>${LOG_FILE}
	echo "vhost admin email : ${vhost_admin}" >>${LOG_FILE}
	echo "vhost server name : ${vhost_servername}" >>${LOG_FILE}
	echo "vhost name aliases : ${vhost_aliases}" >>${LOG_FILE}
	echo "vhost log file : ${vhost_access_log}" >>${LOG_FILE}
	echo "vhost log error file : ${vhost_error_log}" >>${LOG_FILE}
	echo "vhost directory : ${ipam_dirpath}" >>${LOG_FILE}
	echo 
else
	echo "${apache_conf_path}/${apache_conf_ipam} was not created"
	exit 1
fi


if [ -e "${apache_conf_path}/${apache_conf_ipam_ssl}" ]
then
	cat <<- EOF > ${apache_conf_path}/${apache_conf_ipam_ssl}
	<IfModule mod_ssl.c>
        <VirtualHost *:443>
                ServerAdmin ${vhost_admin}
                DocumentRoot ${ipam_dirpath}

                ServerName ${vhost_ssl_servername}
                <Directory ${ipam_dirpath}>
                        Options FollowSymLinks
                        AllowOverride all
                        Order allow,deny
                        Allow from all
                </Directory>

                ErrorLog \${APACHE_LOG_DIR}/${vhost_ssl_error_log}
                CustomLog \${APACHE_LOG_DIR}/${vhost_ssl_access_log} combined

                SSLEngine on

                #   Temp self signed SSLCertificate File.
                SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
                SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

                #   Server Certificate Chain:
                # SSLCertificateChainFile /etc/apache2/ssl.crt/server-ca.crt

                #   Certificate Authority (CA):
                # SSLCACertificatePath /etc/ssl/certs/
                # SSLCACertificateFile /etc/apache2/ssl.crt/ca-bundle.crt

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
	</IfModule>
	EOF
	echo "apache2 ssl conf file created : ${apache_conf_path}/${apache_conf_ipam_ssl}" >>${LOG_FILE}
	echo "vhost ssl admin email : ${vhost_admin}" >>${LOG_FILE}
	echo "vhost ssl server name : ${vhost_ssl_servername}" >>${LOG_FILE}
	echo "vhost ssl log file : ${vhost_ssl_access_log}" >>${LOG_FILE}
	echo "vhost ssl log error file : ${vhost_ssl_error_log}" >>${LOG_FILE}
	echo "vhost directory : ${ipam_dirpath}" >>${LOG_FILE}
else
	echo "${apache_conf_path}/${apache_conf_ipam_ssl} was not created"
	exit 1
fi

# Install phpipam
if [ ! -d "${ipam_dirpath}" ]
then
	mkdir -p ${ipam_dirpath}
	git clone --recursive https://github.com/phpipam/phpipam.git ${ipam_dirpath} >>${LOG_FILE} 2>>${ERROR_FILE}
	cd ${ipam_dirpath}
	git checkout -b ${php_ipam_version} origin/${php_ipam_version} >>${LOG_FILE} 2>>${ERROR_FILE}
	cd ~
	chmod 755 -R ${ipam_dirpath}
	
	if [ -e "${ipam_dirpath}/config.dist.php" ]
	then
		copy_conf=$(cp ${ipam_dirpath}/config.dist.php ${ipam_dirpath}/config.php >>${LOG_FILE} 2>>${ERROR_FILE})
		CPR=$?
		if [[ "$CPR" -ne "0" ]]
		then
			echo "Impossible to copy the config file (${ipam_dirpath}/config.dist.php)."
			exit 1
		else
			# edit config file
			sed -i "s/^\(\$db\['user'\]\s*=\s*\).*\$/\1'${sql_ipam_user}';/" ${ipam_dirpath}/config.php
			sed -i "s/^\(\$db\['pass'\]\s*=\s*\).*\$/\1'${sql_ipam_pwd}';/" ${ipam_dirpath}/config.php
			sed -i "s/^\(\$db\['name'\]\s*=\s*\).*\$/\1'${sql_ipam_db}';/" ${ipam_dirpath}/config.php

			sed -i "s/^\(\$config\['ping_check_send_mail'\]\s*=\s*\).*\$/\1false;/" ${ipam_dirpath}/config.php
			sed -i "s/^\(\$config\['ping_check_method'\]\s*=\s*\).*\$/\1'fping';/" ${ipam_dirpath}/config.php

			sed -i "s/^\(\$config\['discovery_check_send_mail'\]\s*=\s*\).*\$/\1false;/" ${ipam_dirpath}/config.php
			sed -i "s/^\(\$config\['discovery_check_method'\]\s*=\s*\).*\$/\1'fping';/" ${ipam_dirpath}/config.php

			sed -i "s/^\(\$config\['removed_addresses_send_mail'\]\s*=\s*\).*\$/\1false;/" ${ipam_dirpath}/config.php
			sed -i "s/^\(\$config\['removed_addresses_timelimit'\]\s*=\s*\).*\$/\186400 * 7;/" ${ipam_dirpath}/config.php

			sed -i "s/^\(\$config\['resolve_verbose'\]\s*=\s*\).*\$/\1false;/" ${ipam_dirpath}/config.php
			echo "phpipam default config file was edited accordingly to the params defined for mysql/mariadb " >>${LOG_FILE}
		fi
	else
		echo "File '${ipam_dirpath}/config.dist.php' not found ! Required for achieve this process."
		exit 1
	fi
	# Create database, set database permissions, import content
	create_db_query="CREATE DATABASE IF NOT EXISTS ${sql_ipam_db} DEFAULT CHARACTER SET utf8 default COLLATE utf8_bin;"
	grant_db_query_all="GRANT ALL PRIVILEGES ON ${sql_ipam_db}.* TO ${sql_ipam_user}@'%' IDENTIFIED BY '${sql_ipam_pwd}';"
	grant_db_query_local="GRANT ALL PRIVILEGES ON ${sql_ipam_db}.* TO ${sql_ipam_user}@'localhost' IDENTIFIED BY '${sql_ipam_pwd}';"
	SQL_Q1=$(mysql -u root -p${sql_root_pwd} -e "${create_db_query}" >>${LOG_FILE} 2>>${ERROR_FILE})
	SQR1=$?
	SQL_Q2=$(mysql -u root -p${sql_root_pwd} -e "${grant_db_query_all}" >>${LOG_FILE} 2>>${ERROR_FILE})
	SQR2=$?
	SQL_Q3=$(mysql -u root -p${sql_root_pwd} -e "${grant_db_query_local}" >>${LOG_FILE} 2>>${ERROR_FILE})
	SQR3=$?

	if [[ "${SQR1}" -eq "0" && "${SQR2}" -eq "0" && "${SQR3}" -eq "0" ]]
	then
		echo "sql db created : ${sql_ipam_db} with user ${sql_ipam_user} identified by password '${sql_ipam_pwd}'" >>${LOG_FILE}
	
		if [ -e "${ipam_dirpath}/db/SCHEMA.sql" ]
		then 
			SQL_IMPORT=$(mysql -u ${sql_ipam_user} -p${sql_ipam_pwd} ${sql_ipam_db} < ${ipam_dirpath}/db/SCHEMA.sql)
			SQIR=$?
			if [[ "${SQIR}" -eq "0" ]]
			then
				echo "sql phpipam db imported into ${sql_ipam_db}" >>${LOG_FILE}
				update_settings_query="UPDATE settings SET siteTitle = '${ipam_site_title}', siteAdminMail = '${ipam_admin_email}', siteDomain = '${ipam_site_domain}', siteURL = '${ipam_site_url}', donate = '1', enableSNMP = '1', prettyLinks = 'Yes', scanPingType = 'fping' WHERE id = '1';"
				update_users_query="UPDATE users SET lastLogin = NOW(), passChange = 'No', email = '${ipam_admin_email}';"
				SQL_Q4=$(mysql -u root -p${sql_root_pwd} ${sql_ipam_db} -e "${update_settings_query}" >>${LOG_FILE} 2>>${ERROR_FILE})
				SQR4=$?
				SQL_Q5=$(mysql -u root -p${sql_root_pwd} ${sql_ipam_db} -e "${update_users_query}" >>${LOG_FILE} 2>>${ERROR_FILE})
				SQR5=$?
				if [[ "${SQR4}" -eq "0" && "${SQR5}" -eq "0" ]]
				then
					echo "Main configuration changes into the phpipam database are done." >>${LOG_FILE}
				else
					echo "The preconfiguration within the phpipam database was not properly executed." >>${LOG_FILE}
				fi
			else
				echo "Impossible to import phpipam database"
				exit 1
			fi
		fi
	else
		echo "Impossible to create the required database."
		exit 1
	fi
else
	echo "The directory already exists (${ipam_dirpath}). Choose another name."
	exit 1
fi

if [ -e "${ipam_dirpath}/functions/scripts/reset-admin-password.php" ]
then
	SECURE_MYSQL=$(expect -c "
		set timeout 10
		spawn php ${ipam_dirpath}/functions/scripts/reset-admin-password.php
		expect \"Enter new admin password:\"
		send \"${ipam_admin_pass}\r\"
		expect eof
	")
	echo "IPAM Admin password reset"
	echo "IPAM Admin password : ${ipam_admin_pass}" >>${LOG_FILE}
fi
# enable apache2 ssl, then ipam site
if [ -e "/etc/apache2/mods-available/rewrite.load" ]
then
	a2enmod rewrite >>${LOG_FILE} 2>>${ERROR_FILE}
fi

if [ -e "/etc/apache2/mods-available/ssl.conf" ]
then
	a2enmod ssl >>${LOG_FILE} 2>>${ERROR_FILE}
fi

if [ -e "${apache_conf_path}/${apache_conf_ipam}" ]
then
	a2ensite ${apache_vhost_ipam} >>${LOG_FILE} 2>>${ERROR_FILE}
fi

if [ -e "${apache_conf_path}/${apache_conf_ipam_ssl}" ]
then
	a2ensite ${apache_vhost_ipam_ssl} >>${LOG_FILE} 2>>${ERROR_FILE}
fi

systemctl restart apache2 >>${LOG_FILE} 2>>${ERROR_FILE}
echo "Everithin was set up properly."
echo "You can access your ipam website at this address : https://${vhost_ssl_servername}"
echo "You should now generate a csr and set up the required ssl cert for this hostname."
echo "You will find all set passwords in log file : ${LOG_FILE}"
echo "No phpmyadmin is installed on this server. Maybe you would like to install it..."
echo "Bye !"
exit 0