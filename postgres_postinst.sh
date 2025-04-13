#!/bin/bash

echo "Running post-install PostgreSQL tweaks..."

if [[ $(cat /etc/os-release | grep -w "NAME")  == *"AlmaLinux"* ]]
then
    /usr/pgsql-17/bin/postgresql-17-setup initdb
    echo "Enabling PostgreSQL..."
    systemctl start postgresql-17
    systemctl enable postgresql-17
    echo "*:*:*:postgres:12345678" > /var/lib/pgsql/.pgpass
    chmod 600 /var/lib/pgsql/.pgpass
    chown postgres:postgres /var/lib/pgsql/.pgpass
else
    systemctl start postgresql
    systemctl enable postgresql
    echo "*:*:*:postgres:12345678" > /var/lib/postgresql/.pgpass
    chmod 600 /var/lib/postgresql/.pgpass
    chown postgres:postgres /var/lib/postgresql/.pgpass
fi

echo "Creating database and user..."
sudo -u postgres psql -U postgres -c "ALTER ROLE postgres WITH PASSWORD '12345678'"
sudo -u postgres psql -h localhost -U postgres -c "CREATE USER student LOGIN CREATEDB PASSWORD '12345678'"
sudo -u postgres psql -h localhost -U postgres -c "CREATE DATABASE data OWNER student"

echo "Restricting user student to only connect from second ip..."

if [[ $(cat /etc/os-release | grep -w "NAME")  == *"AlmaLinux"* ]]
then

    echo "Creating backups of default files..."
    cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/17/data/pg_hba.conf.bak
    cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/17/data/postgresql.conf.bak

    echo "Allowing student user access only from second host's ip..."
    printf "host\t\tdata\tstudent\t\t%s\t\tscram-sha-256\n" "$1" >> /var/lib/pgsql/17/data/pg_hba.conf

    echo "Allowing connections from any ip..."
    sed -i "61i listen_addresses = '*'\n" /var/lib/pgsql/17/data/postgresql.conf
    printf "host\t\tall\tall\t\t0.0.0.0/0\t\ttrust\n" >> /var/lib/pgsql/17/data/pg_hba.conf

else
    echo "Creating backups of default files..."
    cp /etc/postgresql/17/main/pg_hba.conf /etc/postgresql/17/main/pg_hba.conf.bak
    cp /etc/postgresql/17/main/postgresql.conf /etc/postgresql/17/main/postgresql.conf.bak

    echo "Allowing student user access only from second host's ip..."
    printf "host\t\tall\tstudent\t\t%s\t\tscram-sha-256\n" "$1" >> /etc/postgresql/17/main/pg_hba.conf

    echo "Allowing connections from any ip..."
    sed -i "61i listen_addresses = '*'\n" /etc/postgresql/17/main/postgresql.conf
    printf "host\t\tall\tall\t\t0.0.0.0/0\t\ttrust\n" >> /etc/postgresql/17/main/pg_hba.conf
fi


sudo -u postgres psql -h localhost -U postgres -d data -c 'SELECT 1;'


echo "Post install tweaks finished."

exit 0
