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

insertuser()  {
  echo "Curling to $1"
  resp=$(curl -s $1/auth/generate-password-hash?password=$2)
  echo "Response is $resp"
  password=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['password']")
  salt=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['salt']")
  docker-compose exec -d postgres psql $3 -U $POSTGRESUSER -c "INSERT INTO "users" ("username", "locked", "disabled", "password_hash", "salt") VALUES ('$4', 'false', 'false', '$password', '$salt');"
}

printf "Creating nginx config\n"

if [ $USESSL == 'true' ]
then
  cp nginx-ssl.conf $NGINXCONFDIR/nginx.conf
  sed -i.bak "s|DOMAIN|${NGINXDOMAIN}|g" $NGINXCONFDIR/nginx.conf
else
  cp nginx.conf $NGINXCONFDIR/nginx.conf
fi

cat $NGINXCONFDIR/nginx.conf

printf "Starting up postgres\n"
docker-compose up -d postgres

# When in doubt - set timeout. This should be handled correctly.
sleep 20
printf "\nCreating database $APIDATABASE\n"
docker-compose exec -d postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -c "create database \"$APIDATABASE\""

printf "\nLogin into docker\n"
cat token.txt | docker login https://docker.pkg.github.com -u $GITHUBUSER --password-stdin && docker-compose up -d

printf "\nStarting up all services\n"
docker-compose up -d
sleep 10 # Wait for API to be healthy before creating user

printf "\nInserting user $user into $APIDATABASE\n"
insertuser $BACKENDURL $apipw $APIDATABASE $apiuser

printf "\nInserting user $user into $POSTGRESDATABASE\n"
insertuser $BACKENDURL $matchapw $POSTGRESDATABASE $matchauser
