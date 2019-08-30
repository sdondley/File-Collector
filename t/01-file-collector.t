#/usr/bin/env perl
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector;
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};




my $tests = 14; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 7
{
  my $fc;

  # 1
  throws_ok { $fc = File::Collector->new('blahblahksjdfkjwekjd'); }
    qr/does not exist/, 'rejects bad file or directory';

  # 2
  lives_ok { $fc = File::Collector->new('t/test_data/single_file'); }
    'creates and object';

  # 3
  ok $fc->{files},
    'has files property';

  # 4
  ok $fc->{common_dir},
    'has common_dir property';

  # 5
  is $fc->get_count, 1,
    'gets file count';

  # 6
  my @files;
  lives_ok { @files = $fc->get_files; }
    'can get files';

  # 7
  like $files[0], qr|t/test_data/single_file/a_file.txt$|,
    'gets files';
}

# 8
{
  my $fc = File::Collector->new('t/test_data/nested_dirs', {recurse => 0});

  # 8
  is $fc->get_count, 1,
    'does not recurse';
}

# 9
{
  my $fc = File::Collector->new('t/test_data/nested_dirs');

  # 9
  is $fc->get_count, 2,
    'recurses';
}

# 10 - 12 Constructor error tests
{
  throws_ok { my $fc = File::Collector->new(); }
    qr/No list/, 'dies with no constructor arguments';

  throws_ok { my $fc = File::Collector->new({recurse => 0}, 't/test_data') } qr/Option hash/i,
    'complains when options are not last';

  throws_ok { my $fc = File::Collector->new({recurse => 0}) } qr/No list/i,
    'dies when no resources are passed';
}

# 13 - 14
{
  my $fc = File::Collector->new('t/test_data/many_files');
  stdout_like { $fc->list_files } qr/Files found/,
    'Prints list of files found';

  stdout_like { $fc->list_files } qr/dir1\/file4/,
    'Prints proper list of files found';

#  while ($fc->next_file->next) {
#
#  }
#  my $b = $fc->bundle_files;
#  logd $b;

  my $b = $fc->bundle_files;
  $b->all->blah;

#  while($fc->next_file) {
    #    print $fc->short_name . "\n";
#  }

#  while ($fc->next_file) {
#  }
#  foreach my $file ($fc->get_files) {
#    print $fc->short_name($file) . "\n";
#  }
}






my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
