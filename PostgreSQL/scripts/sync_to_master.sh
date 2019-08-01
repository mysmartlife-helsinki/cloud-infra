#!/bin/bash

# Fabio Pardi on August, 2019

# This script creates a standby syncing from master
# Master must be passed by hand as argument


# Note that this script will wipe out all the data on your local db!

# Pass a master database as argument
master=$1
# This is where the git repo is checked out
git_path=/root/cloud-infra/
# Data folder
PGDATA="/var/lib/postgresql/10/main"


echo " *** WARNING ***"
echo "This script will wipe out all the data on your local db!"
echo "              CTRL-C to stop                            "
echo 
sleep 5

if [ "$(whoami)" != "root" ]
then
    echo "Must run as root. Bailing out!"
    exit 1
fi

if [ ! -n "$master" ]
then
    echo "Please tell me the master to sync from. Bailing out!"
    exit 1
fi 

echo -n "Taking care of git repo.............. "
if [[ ! -d $git_path ]] 
then
    git clone git@github.com:mysmartlife-helsinki/cloud-infra.git || { echo "Error cloning repo" ; exit 1 ; }
else
    cd $git_path
    git  pull -q
fi
echo "OK!"

echo -n "Checking if $master is a master.... "
is_in_recovery=`psql -U appuser postgres -h $master -qtc "select pg_is_in_recovery()"`
if [ "$is_in_recovery" == "t" ]
then
    echo "$master is not a master, bailing out!"
    exit 1 
fi
echo "OK!"

echo -n "Stopping local Postgres.............. "
# Make sure local Postgres is stopped
if systemctl status postgresql > /dev/null
then
	echo "OK!"
else
    counter=0
    systemctl stop postgresql &> /dev/null
    while [ $counter -lt 10 ]
    do
    if ! systemctl status postgresql > /dev/null
    then
        echo "OK! Local Postgres successfully stopped"
        counter=100
    else
        # Postgres can take some time to stop
        echo -n ".."
        sleep 5
        ((counter++))
    fi
    done

    if [ $counter -ne 100  ]
    then
  		echo "NOK! I was not able to stop Postgres. Aborting..."
    exit 1
    fi
fi


# Cleanup data folder, required by pg_basebackup
echo -n "Cleaning up data folder.............. "
rm -fr $PGDATA/* || { echo "NOK! Aborting" ; exit 1 ; }
echo "OK!"

echo 
echo "Now I'm receiving data from master... It will take a while"
pg_basebackup -D $PGDATA -U repluser -R -P -h $master -d "dbname=replication" || { echo "Error running pg_basebackup. Bailing out!" ; exit 1 ; }
echo "OK!"

chown postgres.postgres $PGDATA -R

echo -n "Arranging configuration files........ "
cp $git_path/PostgreSQL/conf/recovery.conf /etc/postgresql/10/main/
sed -i "s,YOUR_MASTER_IP_HERE,$master,g" /etc/postgresql/10/main/recovery.conf
cp $git_path/PostgreSQL/conf/postgresql.conf /etc/postgresql/10/main/
chown postgres.postgres /etc/postgresql/10/main/*.conf
echo "OK!"

echo -n "Starting local Postgres.............. "
systemctl start postgresql > /dev/null || { echo "Error starting PostgreSQL" ; exit 1 ; }
echo "OK!"


echo 
echo "Local Postgres is now receiving streaming from $master"
echo 
