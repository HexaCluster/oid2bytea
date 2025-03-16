use Test::Simple tests => 3;

$ENV{LC_ALL} = 'C';
$ENV{LANG} = 'C';

my $ret = `dropdb oid2bytea_test_src 2>&1`;
ok( $? == 0, "Drop database oid2bytea_test_src");

my $ret = `dropdb OID2BYTEA_TEST_DEST 2>&1`;
ok( $? == 0, "Drop database OID2BYTEA_TEST_DEST");

my $ret = `dropdb oid2bytea_test 2>&1`;
ok( $? == 0, "Drop database oid2bytea_test");

