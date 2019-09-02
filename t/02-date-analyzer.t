#/usr/bin/env perl
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::Date::Classifier;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};




my $tests = 5; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 7
{
  my $da;

  # 1
 lives_ok { $da = File::Collector::Date::Classifier->new('t/test_data/many_files'); }
   'creates Date Classifier object';

 stdout_like { $da->some_files->do->print_blah_names } qr/^dir1\/file4$/ms,
   'prints first file';

 stdout_like { $da->some_files->do->print_short_names } qr/^dir2\/file\d\n[^\n]/ms,
   'prints first file with no double line break';

 is 9, $da->get_some_files, 'returns list of iles from a category';

 stdout_like { while ($da->next_some_file) { $da->print_short_name; } } qr/^file2$/ms,
   'next_ method works';
}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
