package File::Collector::DateClassifier ;

use strict; use warnings;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateClassifier::Iterator;
use parent qw ( File::Collector );

sub _classify_files {
  my ($s, $files_added) = @_;

  $s->add_iterators( qw ( some_files other_files ) );
  foreach my $file (sort @$files_added) {
    $s->add_to_iterator('some_files', $file);
  }
}

return 1;