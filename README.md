# Installing Slussen and Matcha kontraktet as a Docker stack

1. Install docker
2. Set your desired super user login in the .env file (POSTGRESUSER and POSTGRESPASSWORD)
3. Get a personal login token from your github account, save it in token.txt
4. Log in to Github: `cat token.txt | docker login https://docker.pkg.github.com -u yourgithubaccount --password-stdin`
5. Start the database: `docker-compose up postgres`
6. Use your favorite postgres UI tool, log in with the POSTGRESUSER/POSTGRESPASSWORD and db name subletdetector. Create a database called api-db. Assign same owner as to subletdetector database (i.e. POSTGRESUSER).
7. Start the rest of the services: `docker-compose up -d`
8. Get a salt and hash for a Matcha kontraktet user account: http://SERVERIP:9000/auth/generate-password-hash?password=somepassword
9. Create a row in the user table of the subletdetector database
10. Get a salt and hash for an Slussen user account: http://SERVERIP:4000/auth/generate-password-hash?password=somepassword
11. Create a row in the user table of api-db with a username and this salt and hash
12. Update .env: set APIUSERNAME and APIPASSWORD to the username and password above.
13. Update services with new .env values: `docker-compose up -d`
14. Update SYNAIP to the whitelisted IP of your server
15. Access Matcha kontraktet on http://SERVERIP:3000

## Updating to the latest version

1. Get the latest version of the docker images: `docker-compose pull` (no need to stop running containers)
2. Update the stack: `docker-compose up -d`
