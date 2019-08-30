#/usr/bin/env perl
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateClassifier;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};




my $tests = 3; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 7
{
  my $da;

  # 1
 lives_ok { $da = File::Collector::DateClassifier->new('t/test_data/many_files'); }
   'creates DateAnalyzer object';

 stdout_like { $da->some_files->do->print_blah_names } qr/^dir1\/file4$/ms,
   'prints first file';

 stdout_like { $da->some_files->do->print_short_names } qr/^dir1\/file4\ndir1/,
   'prints first file with no double line break';
}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
