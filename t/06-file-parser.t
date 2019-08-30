#/usr/bin/env perl
use lib 't';
use TestUtils;
use Test::Most;
use Test::More;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::FileParser;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};

my $tests = 5; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1
{
  my $fp;

  throws_ok { $fp => Dondley::WestfieldVote::FileParser->new('blahblah'); }
    qr/does not exist/, 'rejects bad file or directory';
}

# 2-5
{
  my $fp;

  lives_ok { $fp = Dondley::WestfieldVote::FileParser->new('t/test_data/file'); }
    'can create object';

  my %ref_check = (
    _parseable_files => 'ARRAY',
    _nonparseable_files => 'ARRAY',
    _files => 'HASH',
  );
  ref_check($fp, \%ref_check);

  is ref $fp, 'Dondley::WestfieldVote::FileParser',
    'returns expected object';

  is scalar @{$fp->{_nonparseable_files}}, 1,
    '_nonparseable_files array populated';
}


# 6-10
{
  my $fp = Dondley::WestfieldVote::FileParser->new('t/test_data/good');

  $fp->add_resources('t/test_data/file');

  lives_ok {
    while ($fp->next_parseable_file) {
      #print $fp->selected_file . "\n";
      while ($fp->next_nonparseable_file) {
        #print $fp->selected_file . "\n";
      }
    }
  }
    'can nest iterators';

  lives_ok { my $bundle = $fp->bundle_parseable_files; }
    'can bundle files';

#  ok $fp->get_data(pop @{($fp->get_files)}), 'can get data from file';

}
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "the code took:",timestr($td),"\n";
