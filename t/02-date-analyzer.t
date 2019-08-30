#/usr/bin/env perl
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateAnalyzer;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};




my $tests = 1; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 7
{
  my $da;

  # 1
 lives_ok { $da = File::Collector::DateAnalyzer->new('t/test_data/many_files'); }
   'creates DateAnalyzer object';

# logd $da->{files};

 $da->{files}{some_files}->do->print_blah_names;
 $da->{files}{some_files}->do->print_short_names;
 $da->some_files->do->print_blah_names;
}







my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
