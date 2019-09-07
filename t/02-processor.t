#/usr/bin/env perl
use Cwd;
use Test::Most;
use Test::Output;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector;
use lib 't/TestMods';
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};



my $tests = 8; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 8
{
  my $da;

 lives_ok { $da = File::Collector->new('t/test_data/many_files', ['Test::Classifier']); }
   'creates Test Classifier object';

 stdout_like { $da->some_files->do->print_blah_names } qr/^dir1\/file4$/ms,
   'prints first file';

 stdout_like { $da->some_files->do->print_short_name } qr/^dir2\/file\d\n[^\n]/ms,
   'prints first file with no double line break';

 stdout_like { while ($da->next_some_file) { $da->print_short_name; } } qr/^file2$/ms,
   'next_ method works';

 my $file = $da->get_file(cwd() . '/t/test_data/many_files/file1');
 is ref ($file), 'HASH',
   'gets hash of file data';

 stdout_like { $da->list_files_long; } qr/file4\n\/\w/,
   'prints out long file paths';

  stdout_like {
    while ($da->next_some_file) {
      $da->print_short_name;
    }
  } qr/file\d\nfile\d/, 'prints out short file names';

  stdout_like {
    my $it1 = $da->get_some_files;
    while ( $it1->next ) {
      # run C<Processor> methods and do other stuff to "good" files
      $it1->print_blah_names;
      my $it2 = $da->get_some_files;
      while ( $it2->next ) {
        $it2->print_blah_names;
      }
    }
  } qr/file\d\n\ndir/, 'prints double spaced file listing';
}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
