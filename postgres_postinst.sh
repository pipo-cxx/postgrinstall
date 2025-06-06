#!/bin/bash

echo "Running post-install PostgreSQL tweaks..."

distro=$(cat /etc/os-release | grep -w "NAME")

if [[ $distro  == *"AlmaLinux"* || $distro == *"CentOS"* ]]
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
    echo "Starting cluster..."
    pg_ctlcluster 17 main start
fi

echo "Creating database and user..."
sudo -u postgres psql -U postgres -c "ALTER ROLE postgres WITH PASSWORD '12345678';"
sudo -u postgres psql -h localhost -U postgres -c "CREATE USER student LOGIN CREATEDB PASSWORD '12345678';"
sudo -u postgres psql -h localhost -U postgres -c "CREATE DATABASE data OWNER student;"

echo "Restricting user student to only connect from second ip..."

if [[ $distro  == *"AlmaLinux"* || $distro == *"CentOS"* ]]
then

    echo "Creating backups of default files..."
    cp /var/lib/pgsql/17/data/pg_hba.conf /var/lib/pgsql/17/data/pg_hba.conf.bak
    cp /var/lib/pgsql/17/data/postgresql.conf /var/lib/pgsql/17/data/postgresql.conf.bak

    echo "Allowing student user access only from second host's ip..."
    printf "host\t\tdata\tstudent\t\t%s\t\tscram-sha-256\n" "$1" >> /var/lib/pgsql/17/data/pg_hba.conf

    echo "Allowing connections from any ip..."
    sed -i "61i listen_addresses = '*'\n" /var/lib/pgsql/17/data/postgresql.conf
#    printf "host\t\tall\tall\t\t0.0.0.0/0\t\ttrust\n" >> /var/lib/pgsql/17/data/pg_hba.conf
    firewall-cmd --permanent --zone="$(firewall-cmd --get-active-zones | sed -n '1p')" --add-port=5432/tcp
    firewall-cmd --reload

else
    echo "Creating backups of default files..."
    cp /etc/postgresql/17/main/pg_hba.conf /etc/postgresql/17/main/pg_hba.conf.bak
    cp /etc/postgresql/17/main/postgresql.conf /etc/postgresql/17/main/postgresql.conf.bak

    echo "Allowing student user access only from second host's ip..."
    printf "host\t\tall\tstudent\t\t%s\t\tscram-sha-256\n" "$1" >> /etc/postgresql/17/main/pg_hba.conf

    echo "Allowing connections from any ip..."
    sed -i "61i listen_addresses = '*'\n" /etc/postgresql/17/main/postgresql.conf
#    printf "host\t\tall\tall\t\t0.0.0.0/0\t\ttrust\n" >> /etc/postgresql/17/main/pg_hba.conf
    chmod 644 /etc/postgresql/17/main/pg_hba.conf
fi

if [[ $distro  == *"AlmaLinux"* || $distro == *"CentOS"* ]]
then
    echo "Restarting PostgreSQL..."
    if systemctl restart postgresql-17
    then
        sudo -u postgres psql -h localhost -d data -c 'SELECT 1;'
    else
        echo "Could not restart PostgreSQL"
    fi
else
    echo "Reloading PostgreSQL..."
    if systemctl reload postgresql
    then
        echo "Restarting cluster..."
        pg_ctlcluster 17 main restart
        sudo -u postgres sh -c "echo SELECT 1\; | psql -h localhost -d data"
    else
        echo "Could not restart PostgreSQL"
    fi
fi

echo "Post install tweaks finished."

exit 0
