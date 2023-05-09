#!/bin/bash
#sudo docker commit artworld_nakama_server_nakama_1 artworld_nakama
#sudo docker save artworld_nakama | gzip | pv | DOCKER_HOST=ssh://root@185.193.67.152 docker load

#sudo docker commit artworld_nakama_server_postgres_1 artworld_postgres
#sudo docker save artworld_postgres | gzip | pv | DOCKER_HOST=ssh://root@185.193.67.152 docker load


# backup local db
sudo docker exec -i artworld_nakama_server_postgres_1 /bin/bash -c "pg_dump -U postgres nakama" > nakama.sql
sftp root@185.193.67.152 <<< $'put nakama.sql'

#drop remote db
ssh root@185.193.67.152 <<< $'sudo docker stop artworld_nakama_server_nakama_1 ;sudo docker exec -i artworld_nakama_server_postgres_1 /bin/bash -c "psql -U postgres -c \'drop database nakama\'"'

# create remote db
ssh root@185.193.67.152 <<< $'sudo docker exec -i artworld_nakama_server_postgres_1 /bin/bash -c "psql -U postgres -c \'create database nakama\'"'

# fill remote db
ssh root@185.193.67.152 <<< $'sudo docker exec -i artworld_nakama_server_postgres_1 /bin/bash -c " psql -U postgres nakama" < nakama.sql; sudo docker start artworld_nakama_server_nakama_1 '

#
