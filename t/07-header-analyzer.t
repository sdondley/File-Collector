#/usr/bin/env perl
use lib 't';
use TestUtils;
use Test::Most;
use Test::More;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::HeaderAnalyzer;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};



my $tests = 4; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1-4
{
  my $ha;

  lives_ok { $ha = Dondley::WestfieldVote::HeaderAnalyzer->new('t/test_data/file'); }
    'can create object';

  my %ref_check = (
    _parseable_files => 'ARRAY',
    _nonparseable_files => 'ARRAY',
    _files => 'HASH',
    _bad_header_files => 'ARRAY',
  );
  ref_check($ha, \%ref_check);

  is ref $ha, 'Dondley::WestfieldVote::HeaderAnalyzer',
    'returns expected object';

  is scalar @{$ha->{_nonparseable_files}}, 1,
    '_nonparseable_files array  populated';
}

{
  my $ha = Dondley::WestfieldVote::HeaderAnalyzer->new('t/test_data/good');
  $ha->add_resources('t/test_data/file');
 logd $ha->{_bad_header_files};


}
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "the code took:",timestr($td),"\n";
