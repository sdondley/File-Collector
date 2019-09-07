package File::Collector::Processor ;
use strict;
use warnings;

use Carp;

use parent 'File::Collector';

sub new {
  my ($class, $all, $cselected, $files) = @_;

  bless { _files => $files || {}, iterator => [], all => $all,
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
  return $s->{selected};
}

sub _isa {
  my $s    = shift;
  my $file = shift;
  defined $s->{_files}{$file};
}

sub _add_file {
  my ($s, $file, $data) = @_;
  $s->{_files}{$file}    = $data; # add the file's data to processor
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
