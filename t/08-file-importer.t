#/usr/bin/env perl
use lib 't';
use TestUtils;
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use Dondley::WestfieldVote::FileImporter;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};


my $tests = 6; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1-4
#{
#  my $fi;
#  dies_ok { $fi = Dondley::WestfieldVote::FileImporter->new('t/test_data/file'); }
#    'dies with non-parseable sheet';
#}
#
#{
#  my $fi2 = '';
#  $fi2 = Dondley::WestfieldVote::FileImporter->new('t/test_data/really_good');
#
#  my %ref_check = (
#    _parseable_files => 'ARRAY',
#    _nonparseable_files => 'ARRAY',
#    _files => 'HASH',
#    _bad_header_files => 'ARRAY',
#  );
#  ref_check($fi2, \%ref_check);
#
#  is ref $fi2, 'Dondley::WestfieldVote::FileImporter',
#    'returns expected object';
#}

{
  my $fi2 = '';
  $fi2 = Dondley::WestfieldVote::FileImporter->new('t/test_data/good');

  my %ref_check = (
    _parseable_files => 'ARRAY',
    _nonparseable_files => 'ARRAY',
    _files => 'HASH',
    _bad_header_files => 'ARRAY',
  );
  ref_check($fi2, \%ref_check);

  is ref $fi2, 'Dondley::WestfieldVote::FileImporter',
    'returns expected object';
}

# uncomment to see output
#{
#  my $fi;
#  $fi = Dondley::WestfieldVote::FileImporter->new('t/test_data/good');
#
#  $fi->print_report;
#}

#{
#  my $fi;
#
#  stderr_like sub { $fi = Dondley::WestfieldVote::FileImporter->new('t/test_data/good') }, qr/(^\[INFO ] Par(.*?)\n){24}/ms,
#    'lists parseable files';
#
#  stderr_like sub { $fi->add_resources('t/test_data/file') }, qr/\[INFO ] Par/,
#    'reports parseable files found for single file';
#
#  $fi->print_report;
#
#  stdout_like sub { $fi->print_report }, qr/(^good(.*?)\n){24}/ms,
#    'reports parseable files found for good files';
#}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\n\nthe code took:",timestr($td),"\n\n";
