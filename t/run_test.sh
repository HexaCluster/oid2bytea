echo "Create the test database" > output.txt
dropdb --if-exists oid2bytea_test > /dev/null 2>&1
createdb oid2bytea_test >> output.txt
if [ $? -ne 0 ]; then
	exit 1
fi
# copy this program into /tmp to be used as a large object
cp -f $0 /tmp/

psql -d oid2bytea_test -c "CREATE TABLE test_oid1 (id integer, bindata oid);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO test_oid1 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 3
fi
# insert missing oid
psql -d oid2bytea_test -c "INSERT INTO test_oid1 VALUES (2, 1234);" >> output.txt 2>&1

psql -d oid2bytea_test -c "CREATE SCHEMA sch1;" >> output.txt 2>&1
psql -d oid2bytea_test -c "CREATE TABLE sch1.test_oid2 (id integer, bindata oid);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO sch1.test_oid2 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test -c "CREATE SCHEMA sch2;" >> output.txt 2>&1
psql -d oid2bytea_test -c "CREATE TABLE sch2.test_oid3 (id integer, bindata oid);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO sch2.test_oid3 VALUES (1, ( SELECT lo_import('/tmp/run_test.sh') ));" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 3
fi

echo "Verify missing oid" >> output.txt
perl oid2bytea -d oid2bytea_test --missing --no-time >> output.txt 2>&1

psql -d oid2bytea_test -c "UPDATE test_oid1 SET bindata = 0 WHERE id = 2;" >> output.txt 2>&1
echo "Migrate only one table" >> output.txt
perl oid2bytea -d oid2bytea_test -z -t test_oid1 --no-time >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 4
fi

echo "must have been migrated" >> output.txt
psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM test_oid1;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 5
fi

echo "must NOT have been migrated" >> output.txt
psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch1.test_oid2;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 6
fi

echo "must NOT have been migrated" >> output.txt
psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch2.test_oid3;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 7
fi

echo "Migrate all tables from schema sch1" >> output.txt
perl oid2bytea -d oid2bytea_test -n sch1 --no-time >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM sch1.test_oid2;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 5
fi

psql -d oid2bytea_test -c "SELECT length(bindata::text) FROM sch2.test_oid3;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 6
fi

echo "Migrate all remaining table" >> output.txt
perl oid2bytea -d oid2bytea_test --no-time >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test -c "SELECT substr(bindata::text, 1, 80) FROM sch2.test_oid3;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 6
fi

echo "Test multi process" >> output.txt
psql -d oid2bytea_test -c "CREATE TABLE test_oid4 (id integer, bindata oid);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO test_oid4 SELECT g.i, lo_import('/tmp/run_test.sh') FROM generate_series(1, 1000) g(i);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 3
fi

psql -d oid2bytea_test -c "CREATE TABLE test_oid5 (id integer, bindata oid);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 2
fi
psql -d oid2bytea_test -c "INSERT INTO test_oid5 SELECT g.i, lo_import('/tmp/run_test.sh') FROM generate_series(1, 2000) g(i);" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 3
fi

echo "Migrating 2 tables at a time splitted by 4" >> output.txt

perl oid2bytea -j 2 -J 4 -d oid2bytea_test --no-time 2>&1
if [ $? -ne 0 ]; then
	exit 4
fi

psql -d oid2bytea_test -c "SELECT count(bindata), sum(length(bindata::text)) FROM test_oid4;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 7
fi

psql -d oid2bytea_test -c "SELECT count(bindata), sum(length(bindata::text)) FROM test_oid5;" >> output.txt 2>&1
if [ $? -ne 0 ]; then
	exit 7
fi
