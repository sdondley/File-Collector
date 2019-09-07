package File::Collector::Processor ;
use strict;
use warnings;

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

__END__

=head1 OVERVIEW

This is the base class for custom C<File::Collector::Processor> classes and is
intended to package methods used to manipulate and inspect files and data
contained in a L<File::Collector> object. To keep this class small and
manageable, it's recommended any heavy file processing be done inside the
objects associated with the files.

C<File::Collector::Processor> objects are not intended to be constructed
directly. Instead, they are created by their respective C<File::Collector>
classes for you automatically.

=head1 SYNOPSIS

  package File::Collector::CustomClassifier::Processor

  use parent 'File::Collector::Processor';

  sub a_useful_method {
    my $s = shift;

    # do useful stuff
    ...
  }

  sub another_useful_method {
    my $s = shift;

    # do more useful stuff
    ...
  }

  sub get_data {
    my $s = shift;
    return $s->get_obj_prop ( 'obj_name', 'some_values' );
  }

=head1 DESCRIPTION

Methods in the C<Processor> classes are typically called from a custom
L<File::Collector> class which should C<use> your custom C<Processor> class.
All methods described will be available to your C<Collector> class as well as
the C<Processor> class.

=method do()

  $collector->some_files->do->run_method;

The C<do> method iterates over all the files classified under the name of the
method call preceding it. In the example above, it will iterate over all the
files classified under "some" by the custom C<Collector> classes using the
C<_classify_file> method. For each file found in the specified category, it
will call C<run_method> of the C<Processor> class returned by the C<do> call.

So for example, if you wanted to delete all the files classified as "bad" files,
that might look something like this:

  $collector->bad_files->do->delete;

The example C<delete> method will takes care of deleting the file for you and
might look somethink like this:

  sub delete {
    my $s = shift;
    unlink $s->selected
  }

Note that we use C<$s-E<gt>selected> to refer to the file currently selected by
the C<Processor>'s iterator. See L<File::Collector::Base> for more details.

=method next()

Initiates a C<Processor> class' iterator on the first call. Iterates over the
files in the C<Processor> on subsequent calls. Returns a boolean false when the
iterator is exhausted/empty. Otherwise, it returns the full path the current
file in the iterator.

=head1 SEE ALSO

L<File::Collector>
