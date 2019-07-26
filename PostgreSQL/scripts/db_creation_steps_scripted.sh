# Steps to perform on a VM in order to run Postgres
# Fabio Pardi on July 2019

# This script is not idempotent, and potentially destructive
# Expects a volume as sdb, not mounted

echo 
echo "Welcome to Postgres installer, created for Ubuntu 18.04"
echo 

# Exit on errors
set -e

echo -n "Creating partition sdb1............. "
echo 'type=83' | sudo sfdisk /dev/sdb
echo "OK!"

echo -n "Creating FS and folder for mount.. "
mkfs.xfs /dev/sdb1
mkdir /pgdata
echo "OK!"

echo -n "Accomodating fstab................ "
echo "UUID=`blkid -s UUID -o value /dev/sdb1` /pgdata           xfs     discard,noatime 1       2" >> /etc/fstab
mount -a 
echo "OK! /pgdata now available"


echo -n "Installing packages............... "
apt-get install postgresql-10 postgresql-client-10 postgresql-10-postgis-2.4  postgresql-10-postgis-scripts > /dev/null
echo "OK! DB is now installed"

#Success. You can now start the database server using:
#/usr/lib/postgresql/10/bin/pg_ctl -D /var/lib/postgresql/10/main -l logfile start

echo -n "Stopping Postgres................. "
systemctl stop postgresql
echo "OK!"

echo -n "Accomodating folders and volumes.. " 
# Make future updates easier 
rsync -a /var/lib/postgresql/ /pgdata/ 
rm -fr /var/lib/postgresql/ 
ln -s /pgdata/ /var/lib/postgresql
echo "OK! You can now connect as:  psql -U postgres -h /var/run/postgresql postgres"



#### SYSTEM SECTION

# Handy, so we can have a single postgresql.conf file. Failover-ready :)
echo -n "Add my internal IP to /etc/hosts.. " 
echo " `ip addr show ens10 | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"`  internal-interface" >> /etc/hosts
echo "OK!"


echo -n "Accomodating Firewall ............ "
ufw allow in on ens10 to any port 5432
echo "OK! Connections on backend to Postgres are allowed. WARNING: NOT FOR PRODUCTION. Access must be fine-graned in order to guarantee better security at network level"


echo -n "Tuning sysctl.conf................ "
echo "vm.overcommit_memory=2" >> /etc/sysctl.conf
echo "vm.overcommit_ratio = 99" >> /etc/sysctl.conf
echo "OK!"
