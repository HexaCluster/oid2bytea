echo "Create the test database 1" > routput.txt
dropdb --if-exists oid2bytea_test_src > /dev/null 2>&1
createdb oid2bytea_test_src >> routput.txt
if [ $? -ne 0 ]; then
	exit 1
fi
# copy this program into /tmp to be used as a large object
cp -f $0 /tmp/

psql -d oid2bytea_test_src -c "CREATE TABLE test_oid1 (id integer, bindata oid);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test_src -c "INSERT INTO test_oid1 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> routput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test_src -c "CREATE SCHEMA sch1;" >> routput.txt
psql -d oid2bytea_test_src -c "CREATE TABLE sch1.test_oid2 (id integer, bindata oid);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test_src -c "INSERT INTO sch1.test_oid2 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> routput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test_src -c 'CREATE SCHEMA "SCH2";' >> routput.txt
psql -d oid2bytea_test_src -c 'CREATE TABLE "SCH2".test_oid3 (id integer, bindata oid);' >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test_src -c "INSERT INTO \"SCH2\".test_oid3 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> routput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

echo "Create the test database 2" >> routput.txt
dropdb --if-exists OID2BYTEA_TEST_DEST >> routput.txt 2>&1
createdb OID2BYTEA_TEST_DEST >> routput.txt 2>&1
if [ $? -ne 0 ]; then
	exit 1
fi

psql -d "OID2BYTEA_TEST_DEST" -c "CREATE TABLE test_oid1 (id integer, bindata bytea);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi

psql -d "OID2BYTEA_TEST_DEST" -c "CREATE SCHEMA sch1;" >> routput.txt
psql -d "OID2BYTEA_TEST_DEST" -c "CREATE TABLE sch1.test_oid2 (id integer, bindata bytea);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi

psql -d "OID2BYTEA_TEST_DEST" -c 'CREATE SCHEMA "SCH2";' >> routput.txt
psql -d "OID2BYTEA_TEST_DEST" -c 'CREATE TABLE "SCH2".test_oid3 (id integer, bindata bytea);' >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi


echo "Migrate only one table remotely" >> routput.txt
perl oid2bytea -d oid2bytea_test_src -D OID2BYTEA_TEST_DEST -t test_oid1 --no-time >> routput.txt
if [ $? -ne 0 ]; then
	exit 4
fi

echo "must have been migrated" >> routput.txt
psql -d "OID2BYTEA_TEST_DEST" -c "SELECT substr(bindata::text, 1, 80) FROM test_oid1;" >> routput.txt
if [ $? -ne 0 ]; then
	exit 5
fi

echo "must NOT have been migrated" >> routput.txt
psql -d "OID2BYTEA_TEST_DEST" -c "SELECT length(bindata::text) FROM sch1.test_oid2;" >> routput.txt
if [ $? -ne 0 ]; then
	exit 6
fi

echo "must NOT have been migrated" >> routput.txt
psql -d "OID2BYTEA_TEST_DEST" -c 'SELECT length(bindata::text) FROM "SCH2".test_oid3;' >> routput.txt
if [ $? -ne 0 ]; then
	exit 7
fi

echo "Migrate all tables from schema sch1 remotely" >> routput.txt
perl oid2bytea -d oid2bytea_test_src -D OID2BYTEA_TEST_DEST -n sch1 --no-time >> routput.txt
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d "OID2BYTEA_TEST_DEST" -c "SELECT substr(bindata::text, 1, 80) FROM sch1.test_oid2;" >> routput.txt
if [ $? -ne 0 ]; then
	exit 5
fi

psql -d "OID2BYTEA_TEST_DEST" -c 'SELECT length(bindata::text) FROM "SCH2".test_oid3;' >> routput.txt
if [ $? -ne 0 ]; then
	exit 6
fi

echo "Migrate all remaining table remotely" >> routput.txt
perl oid2bytea -d oid2bytea_test_src -D OID2BYTEA_TEST_DEST --no-time >> routput.txt
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d "OID2BYTEA_TEST_DEST" -c 'SELECT substr(bindata::text, 1, 80) FROM "SCH2".test_oid3;' >> routput.txt
if [ $? -ne 0 ]; then
	exit 6
fi

echo "Test multi process remotely" >> routput.txt
psql -d oid2bytea_test_src -c "CREATE TABLE test_oid4 (id integer, bindata oid);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test_src -c "INSERT INTO test_oid4 SELECT g.i, lo_import('/tmp/run_test.sh') FROM generate_series(1, 1000) g(i);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test_src -c "CREATE TABLE test_oid5 (id integer, bindata oid);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test_src -c "INSERT INTO test_oid5 SELECT g.i, lo_import('/tmp/run_test.sh') FROM generate_series(1, 2000) g(i);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d "OID2BYTEA_TEST_DEST" -c "CREATE TABLE test_oid4 (id integer, bindata bytea);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d "OID2BYTEA_TEST_DEST" -c "CREATE TABLE test_oid5 (id integer, bindata bytea);" >> routput.txt
if [ $? -ne 0 ]; then
	exit 2
fi

echo "Migrating 2 tables at a time splitted by 4 remotely" >> routput.txt

perl oid2bytea -j 2 -J 4 -d oid2bytea_test_src -D OID2BYTEA_TEST_DEST --no-time
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d "OID2BYTEA_TEST_DEST" -c "SELECT count(bindata), sum(length(bindata::text)) FROM test_oid4;" >> routput.txt
if [ $? -ne 0 ]; then
	exit 7
fi

psql -d "OID2BYTEA_TEST_DEST" -c "SELECT count(bindata), sum(length(bindata::text)) FROM test_oid5;" >> routput.txt
if [ $? -ne 0 ]; then
	exit 7
fi

