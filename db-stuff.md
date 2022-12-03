# bus-cnc.backslasher.net

sudo yum install postgresql
# ./tiny-psql
# PGPASSWORD=??? psql --host=open-bus-big.ctkj9wimtlrm.us-east-1.rds.amazonaws.com --user=??? openbus

curl https://openbus-stride-public.s3.eu-west-1.amazonaws.com/stride_db.sql.gz -o - -s | gunzip | ./tiny-psql

CREATE USER postgres;
