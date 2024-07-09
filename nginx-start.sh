. ./nginx-stop.sh
docker build -t nginx-local .
docker run -d -p 80:80 -p 443:443 --name nginx-local nginx-local
