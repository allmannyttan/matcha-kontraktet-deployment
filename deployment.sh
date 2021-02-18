getvariable() {
  echo $(grep ^$1 .env | cut -d '=' -f2)
}

user=$(getvariable "APIUSERNAME")
pw=$(getvariable "APIPASSWORD")
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
  resp=$(curl -s $1/auth/generate-password-hash?password=$2)
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

printf "Starting up database\n"
docker-compose up -d postgres

sleep 10
printf "\nCreating api-db database\n"
docker-compose exec -d postgres psql subletdetector -U $POSTGRESUSER -c "create database \"$APIDATABASE\""

printf "\nLogin into docker\n"
cat token.txt | docker login https://docker.pkg.github.com -u $GITHUBUSER --password-stdin && docker-compose up -d

printf "\nStarting up all services\n"
docker-compose up -d
sleep 10 # Wait for API to be healthy before creating user

printf "\nInserting Slussen user: $user\n"
insertuser $SLUSSENURL $pw $APIDATABASE $user

printf "\nInserting Matcha-kontraktet user: $user\n"
insertuser $BACKENDURL $pw $POSTGRESDATABASE $user