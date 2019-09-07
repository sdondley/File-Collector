package Test::Classifier ;

use strict; use warnings;
use t::TestMods::Test::Processor;
use Role::Tiny;

sub _init_processors {
  qw ( some other );
}

sub _classify_file {
  my $s = shift;
  $s->_classify('some');
}

1;
