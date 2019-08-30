#/usr/bin/env perl
use lib 't';
use TestUtils;
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::ElectionTypeAnalyzer;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};


my $tests = 1; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1
{
  my $eta;

  lives_ok { $eta = Dondley::WestfieldVote::ElectionTypeAnalyzer->new('t/test_data/really_good'); }
    'can create new object';

  while ($eta->get_next_file) {
    print $eta->get_election_type . "\n";
  }
}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\n\nthe code took:",timestr($td),"\n\n";
