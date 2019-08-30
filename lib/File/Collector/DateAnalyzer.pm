package File::Collector::DateAnalyzer ;

use strict; use warnings;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::DateAnalyzer::Iterator;
use File::Collector::DateAnalyzer::Bundle;
use parent qw ( File::Collector );

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);
  return $obj;
}

sub get_data {
  my $s = shift;
#  return $s->get_obj_prop('data', 'raw_data', $_[0]);
}

sub add_resources {
  my $s = shift;

  $s->SUPER::add_resources(@_);
  $s->{txt_files}      = $s->{txt_files}   || [];
  $s->{other_files}    = $s->{other_files} || [];
  $s->_test_age;
}

sub _test_age {
  my $s = shift;

  foreach my $file ($s->get_files) {
    push @{$s->{txt_files}}, $file;
  }

}

return 1;
