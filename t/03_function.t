use Test::Simple tests => 2;

$ENV{LC_ALL} = 'C';
$ENV{LANG} = 'C';

my $ret = `sh t/run_test_function.sh 2>&1`;
ok( $? == 0, "function use with remote run without error");

my @ret = `diff foutput.txt t/expected/foutput.txt`;
ok( $#ret < 0, "not the expected function+remote output, see diff:\n@ret");


#`rm foutput.txt`;
