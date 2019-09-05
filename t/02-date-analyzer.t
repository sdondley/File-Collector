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




my $tests = 4; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 7
{
  my $da;

  # 1
 lives_ok { $da = File::Collector->new('t/test_data/many_files', ['File::Collector::Date::Classifier']); }
   'creates Date Classifier object';

 stdout_like { $da->some_files->do->print_blah_names } qr/^dir1\/file4$/ms,
   'prints first file';

 stdout_like { $da->some_files->do->print_short_names } qr/^dir2\/file\d\n[^\n]/ms,
   'prints first file with no double line break';

# is 9, $da->get_some_files, 'returns list of iles from a category';

 stdout_like { while ($da->next_some_file) { $da->print_short_name; } } qr/^file2$/ms,
   'next_ method works';

# my @files = $da->get_files;
# logd \@files;

 my $file = $da->get_file('/Users/stevedondley/perl/modules/File-Collector/t/test_data/many_files/file1');

 $da->list_files_long;


  while ($da->next_some_file) {
    $da->print_short_name;
  }

   my $it1 = $da->get_some_files;
   while ( $it1->next ) {
     # run C<Processor> methods and do other stuff to "good" files
     print "outer: ";
     $it1->print_blah_names;
     my $it2 = $da->get_some_files;
     while ( $it2->next ) {
       print "inner: ";
       $it2->print_blah_names;
     }
   }


}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
