package Test::Classifier::Processor ;
use strict;
use warnings;

use Log::Log4perl::Shortcuts qw(:all);
use parent 'File::Collector::Processor';

sub print_blah_names {
  my $s = shift;
  print $s->selected->{short_path} . "\n\n";
}

1; # Magic true value
# ABSTRACT: this is what the module does
