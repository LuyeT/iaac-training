#! /bin/bash
# Author: Thomas Lewis <tluye88@gmail.com>
# Based upon script by Bert Van Vreckem <bert.vanvreckem@gmail.com>
# https://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/

# A non-interactive replacement for mysql_secure_installation
#
# Tested on RHEL8, CENTOS8

set -o errexit # abort on nonzero exitstatus
set -o nounset # abort on unbound variable

#{{{ Functions

usage() {
cat << _EOF_

Usage: ${0} "ROOT PASSWORD"

  with "ROOT PASSWORD" the desired password for the database root user.

Use quotes if your password contains spaces or other special characters.
_EOF_
}

# Predicate that returns exit status 0 if the database root password
# is set, a nonzero exit status otherwise.
is_mysql_root_password_set() {
  ! mysqladmin --user=root status > /dev/null 2>&1
}

# Predicate that returns exit status 0 if the mysql(1) command is available,
# nonzero exit status otherwise.
is_mysql_command_available() {
  which mysql > /dev/null 2>&1
}

is_service_running() {
  systemctl is-active --quiet mariadb
}

#}}}
#{{{ Command line parsing

if [ "$#" -ne "1" ]; then
  echo "Expected 1 argument, got $#" >&2
  usage
  exit 2
fi

#}}}
#{{{ Variables
db_root_password="${1}"
#}}}

# Script proper
$db_root_password"

if ! is_mysql_command_available; then
  echo "The MySQL/MariaDB client mysql(1) is not installed."
  exit 1
fi

if ! is_service_running; then
  echo "Mysql service is not active"
  exit 1
fi

if is_mysql_root_password_set; then
  echo "Database root password already set"
  exit 0
fi

mysql --user=root <<_EOF_
  set password for 'root'@'localhost' = password('${db_root_password}');
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_

#Outdated sql statements
#UPDATE mysql.user SET authentication_string = PASSWORD('${db_root_password}') WHERE User='root';

#sql statements for testing (create undesirable users and DB prior to test if not present)
#SELECT user,host FROM mysql.user;
#SHOW DATABASES;

