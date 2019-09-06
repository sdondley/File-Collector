package Test::Classifier ;

use strict; use warnings;
use lib 't/TestMods';
use Test::Processor;
use Role::Tiny;
use Log::Log4perl::Shortcuts qw(:all);

sub _init_processors {
  qw ( some other );
}

sub _classify_file {
  my $s = shift;
  $s->_classify('some');
}

1;
