package File::Collector::DateAnalyzer ;

use strict; use warnings;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateAnalyzer::Iterator;
use File::Collector::DateAnalyzer::Bundle;
use parent qw ( File::Collector );

sub add_resources {
  my $s = shift;

  $s->SUPER::add_resources(@_);
  my $iterator = ref($s) . '::Iterator';
  $s->{files}{some_files}         = $iterator->new();
  $s->{files}{other_files}        = $iterator->new();
  $s->_test_blah;
}

sub _test_blah {
  my $s = shift;

  foreach my $file ($s->get_files) {
    $s->{files}{some_files}->add_file($s->{files}{all}{$file});
  }

}

return 1;
