# Steps on Timo machines

# manually create sdb1
#fdisk /dev/sdb

echo 
echo "Welcome to Postgres installer, created for Ubuntu 18.04"
echo 
set -e

echo -n "Creating partition sdb1............. "
echo 'type=83' | sudo sfdisk /dev/sdb
echo "OK!"

echo -n "Creating FS and folder for mount.. "
mkfs.xfs /dev/sdb1
mkdir /pgdata
echo "OK!"

echo -n "Accomodating fstab................ "
echo "UUID=`blkid -s UUID -o value /dev/sdb1` /pgdata           xfs     nobarrier,discard,noatime 1       2" >> /etc/fstab
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


