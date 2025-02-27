echo "Migrating oid column using a function send to remote table with text column." > foutput.txt

psql -d oid2bytea_test_src -c "CREATE TABLE test_oidf (id integer, bindata oid);" >> foutput.txt
if [ $? -ne 0 ]; then
	exit 1
fi
psql -d oid2bytea_test_src -c "INSERT INTO test_oidf SELECT g.i, lo_import('/tmp/run_test.sh') FROM generate_series(1, 1000) g(i);" >> foutput.txt
if [ $? -ne 0 ]; then
	exit 2
fi

psql -d oid2bytea_test_dest -c "CREATE TABLE test_oidf (id integer, bindata text);" >> foutput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

perl oid2bytea -J 4 -d oid2bytea_test_src -D oid2bytea_test_dest -f "encode(%, 'escape')" --no-time
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test_dest -c "SELECT count(bindata), sum(length(bindata)) FROM test_oidf;" >> foutput.txt
if [ $? -ne 0 ]; then
	exit 5
fi

psql -d oid2bytea_test_dest -c "SELECT substr(bindata, 1, 10) FROM test_oidf LIMIT 10;" >> foutput.txt
if [ $? -ne 0 ]; then
	exit 6
fi

