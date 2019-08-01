#!/bin/bash

# This utility creates a new database and everything around it 
# Extensions creation, users permissions and so on goes here

# Fabio Pardi on August 2019

# This script to be run as postgres user




#### VARIABLES

# Database name you want to create is passed as first argument
dbname=$1

# Which extensions to create on the db
extensions_wishlist="pg_stat_statements postgis"

#### END OF VARIABLES

### PRE-FLIGHT CHECKS

if [ ! -n "$dbname" ]
then
    echo "Please supply db name as parameter"
    exit 1
fi 

if [ "$(whoami)" != "postgres" ]
then
    echo "Must run as postgres user"
    exit 1
fi

### END OF PRE-FLIGHT CHECKS

echo -n "Creating new database inside the Postgres instance running on this machine"
createdb $dbname || { echo "Error in creating db $dbname" ; exit 1 ;}
echo " OK!"

for extension in $extensions_wishlist
do
    echo -n "Creating extension $extension...."
    psql $dbname -c "CREATE EXTENSION $extension ;"
    echo " OK"
done

# Grant permisssions to the user 'appuser' to newly created db and future objects
for db in postgres $dbname
do
    psql $dbname -c 'ALTER DEFAULT PRIVILEGES  IN SCHEMA public GRANT ALL ON TABLES    TO appuser ; '
    psql $dbname -c 'ALTER DEFAULT PRIVILEGES  IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser ; '
    psql $dbname -c 'ALTER DEFAULT PRIVILEGES  IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser ; '
done
