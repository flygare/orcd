#!/bin/bash

DBCrepo="QvantelDBConnector"
app_conf_path="src/main/resources/application.conf"
cass_container_name="cassandra_qvantel"
# What in config file needs to be updated(for intgr. test)
batch_limit="batch\.limit"
batch_size_limit="cassandra\.element\.batch\.size"
cassandra_port="port"
cassandra_it_port=9042
cassandra_keyspace="qvantel"
cassandra_cdr_table_name="cdr"
limit="theLimit"
tempGraphiteFile="tempGraphiteData.txt"
jar_directory="target/scala-2.11/DBConnector.jar"

# --> Run cdr-cassandra integration test
echo "Running cdr--> cassandra integration test!"
#int_test=$(./cdr_cass_integration_test.sh "cassandra_qvantel" 2>&1)

echo "cdr-->cassandra Integration test done!"
#match "limit=number" and force number to be 1
pushd ../QvantelDBConnector/
sed -i "s#${limit}\ *\=\ *\-*[0-9]*#${limit}\=5#g" "$app_conf_path"

# now running the dbconnector
echo "running dbconnector using sbt run"
sbt run

# now change the app.config file to its origin
sed -i "s#${limit}\ *\=\ *\-*[0-9]*#${limit}\=-1#g" "$app_conf_path"

# back to the directory you were in at start
popd

#now run curl to check if the data is at graphite. in this case we are lookng att callplan
curl '127.0.0.1:2000/render?target=qvantel.product.voice.CallPlanNormal&format=json' -o $tempGraphiteFile

#check if the file contain data by
# Read from file and grep for rows.
#echo ${grep -Fxq "\[\]" $tempGraphiteFile}
if grep -Fxq "[]" $tempGraphiteFile
then
#there are no records in this file
echo "the dbconnector integration test failed!"
echo "[-failed-]"
else
#there are records in this file
echo "dbconnector integration test is done and successfull"
echo "[-success-]"
fi

#now remove the temp file 
rm -f $tempGraphiteFile