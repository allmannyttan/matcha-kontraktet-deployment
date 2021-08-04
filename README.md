# Installing Slussen and Matcha kontraktet as a Docker stack

1. Install Docker Engine (https://docs.docker.com/engine/install/)
2. Install Docker Compose (https://docs.docker.com/compose/install/)
3. Rename `env.template` to `.env`
4. Change the following variables:
   1. POSTGRESDBUSER/POSTGRESPASSWORD - superuser that will be created for postgres
   2. APIUSERNAME/APIPASSWORD - service account that will created for Slussen
   3. If you use Syna:
      1. SYNAIP - your whitelisted IP at Syna
      2. SYNAUSER/SYNACUSTOMERNUMBER - your login at Syna
   4. If you use Creditsafe (TODO)
   5. FASTAPIUSER/FASTAPIPASSWORD - service account to access fastAPI.
   6. FASTAPIBASEURL - URL for fastAPI (usually ends in /v1/api/)
   7. BACKENDURL -
   7. USESSL - if true, will use https for frontend and backen. You need a certificate (.crt and .key files).
      1. NGINXCONFDIR - a directory where nginx.conf will be placed, full or relative to where deployment.sh and subsequently docker-compose is run.
      2. NGINXSSLDIR - a directory where you place certificate.crt and certificate.key, full or relative to where deployment.sh and subsequently docker-compose is run.
      3. NGINXDOMAIN - the domain name matchning your certificate
   8. BACKENDURL - https://NXGINXDOMAIN/backend (or http://localhost/backend if USESSL is false)
   9. GITHUBUSER - the user account used to retrieve docker images (see below)
5. Get a personal login token with read:packages access from your github account, save it in token.txt (https://https://github.com/settings/tokens)
6. Run deployment script `sh ./deployment.sh`
7. Access the service at https://NGINXDOMAIN or (http://localhost if USESSL is false)

## Updating to the latest version

1. cd to the installation directory (where ./deployment.sh was run)
2. Get the latest version of the docker images: `docker-compose pull` (no need to stop running containers)
3. Update the stack: `docker-compose up -d`
