# Create the test database
dropdb --if-exists oid2bytea_test > /dev/null 2>&1
createdb oid2bytea_test > output.txt
if [ $? -ne 0 ]; then
	exit 1
fi
# copy this program into /tmp to be used as a large object
cp -f $0 /tmp/

psql -d oid2bytea_test -c "CREATE TABLE test_oid1 (id integer, bindata oid);" >> output.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO test_oid1 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test -c "CREATE SCHEMA sch1;" >> output.txt
psql -d oid2bytea_test -c "CREATE TABLE sch1.test_oid2 (id integer, bindata oid);" >> output.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO sch1.test_oid2 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test -c "CREATE SCHEMA sch2;" >> output.txt
psql -d oid2bytea_test -c "CREATE TABLE sch2.test_oid3 (id integer, bindata oid);" >> output.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO sch2.test_oid3 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt
if [ $? -ne 0 ]; then
	exit 3
fi

# Migrate only one table
perl oid2bytea -d oid2bytea_test -t test_oid1 --no-time >> output.txt
if [ $? -ne 0 ]; then
	exit 4
fi

# must have been migrated
psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM test_oid1;" >> output.txt
if [ $? -ne 0 ]; then
	exit 5
fi
# must NOT have been migrated
psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch1.test_oid2;" >> output.txt
if [ $? -ne 0 ]; then
	exit 6
fi
# must NOT have been migrated
psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch2.test_oid3;" >> output.txt
if [ $? -ne 0 ]; then
	exit 7
fi

# Migrate all tables from schema sch1
perl oid2bytea -d oid2bytea_test -n sch1 --no-time >> output.txt
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM sch1.test_oid2;" >> output.txt
if [ $? -ne 0 ]; then
	exit 5
fi

psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch2.test_oid3;" >> output.txt
if [ $? -ne 0 ]; then
	exit 6
fi

# Migrate all remaining table
perl oid2bytea -d oid2bytea_test --no-time >> output.txt
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM sch2.test_oid3;" >> output.txt
if [ $? -ne 0 ]; then
	exit 6
fi


