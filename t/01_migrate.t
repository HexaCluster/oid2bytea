use Test::Simple tests => 4;

$ENV{LC_ALL} = 'C';
$ENV{LANG} = 'C';

my $ret = `sh t/run_test.sh 2>&1`;
ok( $? == 0, "run without error");

my @ret = `diff output.txt t/expected/output.txt`;
ok( $#ret < 0, "not the expected output, see diff:\n@ret");

$ret = `sh t/run_test_remote.sh 2>&1`;
ok( $? == 0, "remote run without error");

@ret = `diff routput.txt t/expected/routput.txt`;
ok( $#ret < 0, "not the expected remote output, see diff:\n@ret");


`rm output.txt`;
`rm routput.txt`;
