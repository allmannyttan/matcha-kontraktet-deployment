# Installing Slussen and Matcha kontraktet as a Docker stack

1. Install docker
2. Set your desired super user login in the .env file (POSTGRESUSER and POSTGRESPASSWORD)
3. Update .env: set APIUSERNAME and APIPASSWORD to the username and password of your choice.
4. Get a personal login token from your github account, save it in token.txt
5. Run deployment script `sh ./deployment.sh`
6. Update SYNAIP to the whitelisted IP of your server
7. Access Matcha kontraktet on http://SERVERIP:3000

## Updating to the latest version

1. Get the latest version of the docker images: `docker-compose pull` (no need to stop running containers)
2. Update the stack: `docker-compose up -d`
