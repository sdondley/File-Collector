package File::Collector::DateAnalyzer ;

use strict; use warnings;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateAnalyzer::Iterator;
use parent qw ( File::Collector );

sub add_resources {
  my $s = shift;

  $s->SUPER::add_resources(@_);
  $s->add_iterators( qw ( some_files other_files ) );
  $s->_classify_files;
}

sub _classify_files {
  my $s = shift;

  foreach my $file ($s->get_files) {
    $s->{files}{some_files}->add_file($s->{files}{all}{$file});
  }

}

return 1;
