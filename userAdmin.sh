#!/bin/bash

Help()
{
   # Display Help
   echo "Add, delete or list users for the Matcha-Kontrakt application."
   echo
   echo "Syntax: userAdmin [-h|-a|-d|-l]"
   echo "options:"
   echo "-h        Print this Help."
   echo "-a user   Add user."
   echo "-d user   Delete user."
   echo "-l        List existing users."
   echo
}

# Avoid users to run as root / sudo
if [[ $(id -u) = 0 ]] ; then echo "Please do not run as root\nAdd the user you want to run under to the docker group." ; exit 1 ; fi

getvariable() {
  echo $(grep ^$1 .env | cut -d '=' -f2)
}

BACKENDURL="http://localhost:9000"
POSTGRESDATABASE=$(getvariable "POSTGRESDATABASE")
POSTGRESUSER=$(getvariable "POSTGRESUSER")

insertUser()  {
  resp=$(curl -s ${BACKENDURL}/auth/generate-password-hash?password=$2)
  echo "Response is $resp"
  password=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['password']")
  salt=$(echo $resp | python -c "import sys, json; print json.load(sys.stdin)['salt']")
  docker-compose exec postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -c "INSERT INTO "users" ("username", "locked", "disabled", "password_hash", "salt") VALUES ('$1', 'false', 'false', '$password', '$salt');"
}

deleteUser() {
    docker-compose exec postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -AXtc "DELETE FROM users WHERE username = '$1';" 
}

listUsers() {
    docker-compose exec postgres psql $POSTGRESDATABASE -U $POSTGRESUSER -AXtc "SELECT username FROM users;" 
}

while getopts ":ha:d:l" option; do
   case "${option}" in
      h) # display Help
         Help
         exit;;
      a) # Enter a name
         echo "Please enter a password for user: ${OPTARG}"
         read PASSWORD
         insertUser ${OPTARG} ${PASSWORD}
         exit;;
      d) # Delete a user
         echo "Deleting user: ${OPTARG}"
         deleteUser ${OPTARG}
         exit;;
      l) # List users
         listUsers
         exit;;
      *) # Invalid option
         echo "Error: Invalid option"
         Help
         exit;;
   esac
done

# In case no parameters were provided
Help
