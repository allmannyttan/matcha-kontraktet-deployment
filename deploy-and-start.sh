#!/bin/bash

# Avoid users to run as root / sudo
if [[ $(id -u) = 0 ]] ; then echo "Please do not run as root\nAdd the user you want to run under to the docker group." ; exit 1 ; fi

getvariable() {
  echo $(grep ^$1 .env | cut -d '=' -f2)
}

apiuser=$(getvariable "APIUSERNAME")
apipw=$(getvariable "APIPASSWORD")
matchauser=$(getvariable "MATCHAUSERNAME")
matchapw=$(getvariable "MATCHAPASSWORD")
SLUSSENURL="http://localhost:4000"
BACKENDURL="http://localhost:9000"
POSTGRESDATABASE=$(getvariable "POSTGRESDATABASE")
POSTGRESUSER=$(getvariable "POSTGRESUSER")
APIDATABASE=$(getvariable "APIDATABASE")
DOCKERPW=$(getvariable "DOCKERPW")
NGINXCONFDIR=$(getvariable "NGINXCONFDIR")
NGINXSSLDIR=$(getvariable "NGINXSSLDIR")
NGINXDOMAIN=$(getvariable "NGINXDOMAIN")
USESSL=$(getvariable "USESSL")
GITHUBUSER=$(getvariable "GITHUBUSER")
SSLCRTPATH=$(getvariable "SSLCRTPATH")
SSLKEYPATH=$(getvariable "SSLKEYPATH")

insertuser()  {
  echo "Curling to $1"
  resp=$(curl -s $1/auth/generate-password-hash?password=$2)
  echo "Response is $resp"
  password=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['password']")
  salt=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['salt']")
  docker-compose exec -d postgres psql $3 -U $POSTGRESUSER -c "INSERT INTO "users" ("username", "locked", "disabled", "password_hash", "salt") VALUES ('$4', 'false', 'false', '$password', '$salt');"
}

try() {
  count=1
  while $1
  do  
    echo "Waiting"
    ((count++))
    if [ $count -gt $2 ]
    then
      echo $4
      exit 1
    fi
    sleep $3
  done
}

dbIsRunning() {
  local dbExists=$(docker-compose exec postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -c "SELECT datname FROM pg_catalog.pg_database WHERE datname='subletdetector'")
  local rowStr="(1 row)" 
  if [[ "$dbExists" == *"$rowStr"* ]]
  then 
    return 1
  else 
    return 0
  fi  
}

backendRunning() {
  if [ $(curl -o /dev/null -s -w "%{http_code}" $BACKENDURL) -ne 200 ]
  then 
    return 0
  else 
    return 1
  fi
}

printf "Creating nginx config\n"

if [ $USESSL = 'true' ]
then
  cp nginx-ssl.conf $NGINXCONFDIR/nginx.conf
  sed -i.bak -e "s|SSLCRTPATH|/etc/ssl/${SSLCRTPATH}|g" -e "s|SSLKEYPATH|/etc/ssl/${SSLKEYPATH}|g" -e "s|DOMAIN|${NGINXDOMAIN}|g" $NGINXCONFDIR/nginx.conf
else
  cp nginx-nossl.conf $NGINXCONFDIR/nginx.conf
fi

cat $NGINXCONFDIR/nginx.conf

printf "Starting up postgres\n"
docker-compose up -d postgres

# Wait until db is up (max 10 times)
try dbIsRunning 10 10 "Failed to startup postgres database"

printf "\nCreating database $APIDATABASE\n"
docker-compose exec postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -c "create database \"$APIDATABASE\""

printf "\nStarting up all services\n"
docker-compose up -d

# Wait until db is up (max 10 times)
try backendRunning 10 10 "Failed to startup backend"

printf "\nInserting user $user into $APIDATABASE\n"
insertuser $BACKENDURL $apipw $APIDATABASE $apiuser

printf "\nInserting user $user into $POSTGRESDATABASE\n"
insertuser $BACKENDURL $matchapw $POSTGRESDATABASE $matchauser
