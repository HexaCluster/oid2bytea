use Test::Simple tests => 2;

$ENV{LC_ALL} = 'C';
$ENV{LANG} = 'C';

my $ret = `sh t/run_test.sh 2>&1`;
ok( $? == 0, "run without error");

my @ret = `diff output.txt t/expected/output.txt`;
ok( $#ret < 0, "not the expected output, see diff:\n@ret");

`rm output.txt`;
