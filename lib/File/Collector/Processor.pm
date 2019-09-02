package File::Collector::Processor ;
use strict;
use warnings;

use Carp;
use Log::Log4perl::Shortcuts       qw(:all);

use parent 'File::Collector::Base';

sub new {
  my ($class, $all, $cselected) = @_;

  bless { _files => {}, iterator => [], all => $all,
          selected => '', cselected => $cselected }, $class;
}

sub next {
  my $s = shift;
  if (!$s->selected) {
    my @files = values %{$s->{_files}};
    $s->{iterator} = \@files;
  }
  my $file               = shift @{$s->{iterator}};
  $s->{selected}         = $file;
  ${$s->{cselected}}     = $file->{full_path};
}

sub isa {
  my $s    = shift;
  my $file = $s->selected;
  defined $s->{_files}{$file};
}

sub _add_file {
  my ($s, $file, $data) = @_;
  $s->{_files}{$file}    = $data; # add the file's data to processor
}

sub print_short_names {
  my $s = shift;
  print $s->selected->{short_path} . "\n";
}

sub do {
  my $s = shift;
  bless \$s, 'File::Collector::Processor::Do';
}

{
  package File::Collector::Processor::Do;
  use Log::Log4perl::Shortcuts qw(:all);

  sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my ($method) = $AUTOLOAD =~ m/::([^:]+)$/;
    $$self->$method(@_) while ($$self->next);
  }

  sub DESTROY {}
}

1; # Magic true value
# ABSTRACT: this is what the module does


