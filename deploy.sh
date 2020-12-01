cat ~/token.txt | docker login https://docker.pkg.github.com -u osirisguitar --password-stdin
docker-compose build && docker-compose -d up
