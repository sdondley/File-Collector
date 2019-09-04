package File::Collector::Date::Classifier ;

use strict; use warnings;
use Role::Tiny;
use Log::Log4perl::Shortcuts qw(:all);
use File::Collector::Date::Processor;

sub _init_processors {
  qw ( some other );
}

sub _classify_file {
  my $s = shift;
  $s->_classify('some');
}

sub _run_processes {
}

1;
