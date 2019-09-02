package File::Collector::Date::Classifier ;

use strict; use warnings;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::Date::Processor;
use parent qw ( File::Collector );

sub _init_processors {
  my $s = shift;

  $s->SUPER::_init_processors( @_, qw ( some other ) );
}

sub _classify_file {
  my $s = shift;

  $s->_classify('some');
}

1;
