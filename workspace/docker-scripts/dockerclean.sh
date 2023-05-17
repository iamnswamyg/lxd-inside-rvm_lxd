bundle exec kitchen destroy 
docker stop $(docker ps -q)
docker rm $(docker ps -a -q)
docker images -a | grep none | awk '{ print $3; }' | xargs docker rmi --force
docker images -a | grep kitImage | awk '{ print $3; }' | xargs docker rmi --force
rm -rf ./.kitchen/logs
rm -f ./.kitchen/.*yml