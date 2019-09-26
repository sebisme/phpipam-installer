# PHPIPAM INSTALLER

This script is a small tool used to automate the deployment of **phpipam** on a brand new clean **debian 9** install.
All my gratitude to **Miha Petkovsek**, creator of phpipam.

Find out more about [phpipam](https://phpipam.net) and [phpipam](https://github.com/phpipam/phpipam) on [github](https://github.com)
To install [debian](https://debian.org)

**N.B.** : It will be soon tested for **debian 10**

## What the script does

* It installs several tools and utils on your debian 9 server
  * `mariadb-client` and `mariadb-server` (MySQL)
  * `expect` and `jq` (for config. purposes)
  * `snmp`, `snmpd`, `fping` (required for phpipam)
  * `apache2`, `openssl`, `php7.0` (and all the required php7 plugins required by phpipam)
  * `git`
  * `vim` and `vim-pathogen`
  * `netcat`, `tcpdump`, `dnsutils` (because it is always useful on a server, especially one for phpipam)
* It sets the root password for mariadb
* It configures apache2 vhost and ssl vhost for phpipam
* It clones the github repo of phpipam, checkout on the configured version
* It configures the config.php file
* It creates a DB for phpipam, load the phpipam DB schema
* It restarts apache, and you're good to go ! (you still need to install your own valid ssl certificate)

## How to use

Install a clean debian 9, copy the script in your home directory, make the script executable

```shell
chmod +x ./phpipam_installer.sh
```
Then, simply run the script (as root)

```shell
./phpipam_installer.sh
```

## Configuration

Before copying the script, you can edit all variables as needed

* `ipam_admin_email` : PHPIPAM ADMIN EMAIL
* `ipam_admin_pass` : PHPIPAM ADMIN PASSWORD
* `ipam_site_title` : PHPIPAM SITE TITLE
* `ipam_site_domain` : PHPIPAM SITE DOMAIN NAME
* `ipam_site_host` : PHPIPAM SITE HOST NAME
* `ipam_site_url_scheme` : PHP IPAM URL SCHEME (http or https)
* `ipam_parentpath` : PHPIPAM PARENT DIRECTORY PATH
* `ipam_dirname` : PHPIPAM DIRECTORY
* `vhost_admin` : PHPIPAM APACHE VHOST ADMIN
* `vhost_aliases` : PHPIPAM APACHE VHOST ALIASES
* `vhost_error_log` : PHPIPAM APACHE VHOST ERROR LOG NAME
* `vhost_access_log` : PHPIPAM APACHE VHOST ACCESS LOG NAME
* `vhost_ssl_error_log` : PHPIPAM APACHE SSL VHOST ERROR LOG NAME
* `vhost_ssl_access_log` : PHPIPAM APACHE SSL VHOST ACCESS LOG NAME
* `apache_conf_path` : PHPIPAM APACHE VHOST CONFIG PATH
* `apache_vhost_ipam` : PHPIPAM APACHE VHOST NAME
* `apache_vhost_ipam_ssl` : PHPIPAM APACHE SSL VHOST NAME
* `php_ipam_version` : PHPIPAM VERSION (actual stable : 1.4)
* `sql_root_pwd` : MySQL (mariadb) ROOT PASSWORD
* `sql_ipam_user` : MySQL (mariadb) PHPIPAM USER
* `sql_ipam_pwd` : MySQL (mariadb) PHPIPAM USER PASSWORD
* `sql_ipam_db` : MySQL (mariadb) PHPIPAM DB NAME