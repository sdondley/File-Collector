package File::Collector ;
use strict; use warnings;

use Cwd;
use Carp;
use File::Basename;
use Log::Log4perl::Shortcuts qw(:all);

use parent 'File::Collector::Base';

# public methods

sub AUTOLOAD {
  our $AUTOLOAD;
  my $s = shift;
  $AUTOLOAD  =~ /.*::(next_|isa_|get_)*(\w+)_files*$/ or
    croak "No such method: $AUTOLOAD";

  if (!$s->{files}{"$2_files"}) { $s->_scroak("No such file category exists: '$2' at "); }
  else { return $s->{files}{"$2_files"} if !$1; }

  if ($1 eq 'next_') {
    return $s->{files}{"$2_files"}->next;
  }

  if ($1 eq 'isa_') {
    return $s->{files}{"$2_files"}->isa;
  }

  if ($1 eq 'get_') {
    return values %{$s->{files}{"$2_files"}};
  }

  croak "No such method: $AUTOLOAD";
}

sub new {
  my $class = shift;

  # Check args
  if (!@_ || (@_ == 1 && ref($_[0]) eq 'HASH')) {
    croak ('No list of files or directories supplied to constructor. Aborting.');
  }

  my @tmp = @_;
  pop @tmp;
  for my $r (@tmp) {
    croak ('Option hash should be passed to constructor last. Aborting')
      if (ref($r)) eq 'HASH';
  }

  # get options hash
  my $user_opts    = {};
  my $default_opts = { recurse => 1 };
  if (ref $_[-1] eq 'HASH') {
    $user_opts    = pop @_;
  }
  my %opts = (%$default_opts, %$user_opts);

  my $s = bless {
    files          => { all => {} },
    common_dir     => '',
    selected       => '',
    options        => \%opts,
  }, $class;

  $s->{all} = $s->{files}{all};

  $s->add_resources(@_);
  return $s;
}

sub add_resources {
  my ($s, @resources) = @_;

  # collect the files
  foreach my $resource (@resources) {
    $s->_exists($resource);
    $s->_add_file($resource)          if -f $resource;
    $s->_get_file_manifest($resource) if -d $resource;
  }

  $s->_generate_short_names;                    # calculate the short names
  $s->_init_processors;
  foreach my $file (@{$s->{files}{new_files}}) {
    $s->{selected} = $file;
    $s->_classify_file;
  }
  $s->_run_processes;
  undef $s->{selected};
  undef $s->{files}{new_files};                 # clear the new_file array
}

sub get_count {
  my $s = shift;
  return (scalar keys %{$s->{files}{all}})
}

sub get_files {
  my $s = shift;

  my @files = sort keys %{$s->{files}{all}};
  return @files;
}

sub list_files_long {
  my $s = shift;

  my @files = $s->get_files;
  print $_ . "\n" for @files;
}

sub list_files {
  my $s = shift;

  my @files = map { $s->{files}{all}{$_}{short_path} } sort keys %{$s->{files}{all}};
  print "\nFiles found in '".$s->{common_dir}."':\n\n";
  print $_ . "\n" for @files;
}

sub print_short_name {
  my $s = shift;
  print $s->short_name . "\n";
}

sub DESTROY {
}

# private methods

sub _init_processors {
  my ($s, @processors) = @_;

  my $class    = ref($s);
  $class       =~ s/::(\w)+$//;
  my $it_class = $class . '::Processor';

  foreach my $it ( @processors ) {
    next if ($s->{files}{"${it}_files"});    # don't overwrite existing processor
    $s->{files}{"${it}_files"} = $it_class->new($s->{files}{all});
  }
}

sub _generate_short_names {
  my $s = shift;

  my @files                         = $s->get_files;
  my $file                          = pop @files;
  my @comps                         = split /\//, $file;
  my ($new_string, $longest_string) = '';
  foreach my $cfile (@files) {
    my @ccomps = split /\//, $cfile;
    my $lc     = 0;

    foreach my $comp (@ccomps) {
      if (defined $comps[$lc] && $ccomps[$lc] eq $comps[$lc]) {
        $new_string   .= $ccomps[$lc++] . '/';
        next;
      }
      $longest_string = $new_string;
      @comps          = split /\//, $new_string;
      $new_string     = '';
      last;
    }
  }

  $s->{common_dir} = $longest_string || (fileparse($file))[1];

  if (@files) {
    foreach my $file ( @files, $file ) {
      $s->{files}{all}{$file}{short_path} = $file =~ s/$longest_string//r;
    }
  } else {
    $s->{files}{all}{$file}{short_path} = $file;
  }
}

sub _classify {
  my ($s, $type) = @_;
  my $file = $s->selected;
  my $t = $type . '_files';

  # die if bad args given
  $s->_croak("No $type argument sent to _classify method. Aborting.") if !$type;
  $s->_croak("No processor called $type exists. Aborting.") if !$s->{files}{$t};

  $s->{files}{$t}->_add_file($file, $s->{files}{all}{$file});
}

sub _add_file {
  my ($s, $file) = @_;

  $file                                 = $s->_make_absolute($file);
  $s->{files}{all}{$file}{full_path}    = $file;
  my $filename                          = (fileparse($file))[0];
  $s->{files}{all}{$file}{filename}     = $filename;

  push @{$s->{files}{new_files}}, $file if !$s->{files}{$file};
}

sub _add_obj {
  my ($s, $type, $obj) = @_;
  $s->_scroak("Missing args to 'add_obj' method. Aborting.") if (!$type || !$obj);

  $s->{files}{all}{$s->selected}{"${type}_obj"} = $obj;
}

sub _make_absolute {
  my ($s, $file) = @_;

  return $file =~ /^\// ? $file : cwd() . "/$file";
}

sub _get_file_manifest {
  my ($s, $dir) = @_;

  opendir (my $dh, $dir) or die "Can't opendir $dir: $!";
  my @dirs_and_files = grep { /^[^\.]/ } readdir($dh);

  my @files = grep { -f "$dir/$_" } @dirs_and_files;
  $s->_add_file("$dir/$_") for @files;

  my @dirs  = grep { -d "$dir/$_" } @dirs_and_files if $s->{options}{recurse};
  foreach my $tdir (@dirs) {
    opendir (my $tdh, "$dir/$tdir") || die "Can't opendir $tdir: $!";
    $s->_get_file_manifest("$dir/$tdir");
  }

}

# fallback stub methods needed if not used by any subclasses

sub _classify_file {
}

sub _run_processes {
}

1; # Magic true value
# ABSTRACT: Collects files and sets up file Processors

__END__

=head1 OVERVIEW

C<File::Collector> and its companion module C<File::Collector::Processor> are
base classes designed to make it easier for creating custom modules to classify
and process a collection of files as well as generate, track and process data
related to files in the collection.

For example, let's say you need to import raw files from one directory into some
kind of repository. Let's say that files in the directory need to be filtered
and the content of the files needs to be parsed, validated, rendered and/or
changed before getting imported. Complicating things further, let's say that the
name and location of the file in the target repository is dependent upon the
content of the files in some way. Oh, and you also have to check to make sure
the file hasn't already been imported.

This kind of task can be acomplished with a series of one-off scripts that
process and import your files with each script producing output suitable for the
next script. But if such imports occur regularly or involve a high level of
complexity, running separate scripts for each processing stage can be slow,
tedious, error-prone and not easily reproducible.

The C<File::Collector> and C<File::Collector::Processor> base modules can help
you set up a chain of modules to combine a series of workflows into a single
logical package that will make complicated file processing more robust and
testable as well far less tedious and much faster to code.

=head1 SYNOPSIS

First, create your custom class with the appropriate methods for classifying files
and setting up the processors.

  pakcage File::Collector::YourClassifier;
  use strict; use warnings;

  # This package contains your processing methods (see below)
  use File::Collector::YourClassifier::Processor;

  # The parent of this class is another File::Collector class. This is how you
  # chain your Collectors and Processors together.
  use parent File::Collector::AnotherCustomFileClassifier;

  # Add the names of your custom processor here. Processors are just a
  # collection of files with associated methods that make it convenient for
  # manipulating files and their data.
  sub _init_processors {
    my $s = shift;
    $s->SUPER::_init_processors( @_, qw ( good bad ) );
  }

  # This method is called once for each new file found. It classifies your
  # files and create objects which can be associated with your files.
  sub _classify_file {
    my $s = shift;

    # allow parent classes to classify the files first
    $s->SUPER::_classify_file;

    # create an object and pass the name of the file to it
    # $s->selected is automatically set to include the  the name of the file
    # getting processed so you don't have to think about it.
    my $data = SomeObject->new( $s->selected );

    # associate the newly created object with the file
    $s->add_obj('data', $data);

    # Classify the files according to criteria you determine to add the file
    # to a processor category
    if ( $data->{has_property} ) {
      $s->classify('good');
    } else {
      $s->classify('bad');
    }
  }

  # The _run_processes method contains method calls to your processors
  sub _run_processes {
    my $s = shift;

    # run processes of parent classes first
    $s->SUPER::_run_processes;

    # Run some methods on files classified as "good". The "do" method is a
    # method that automatically iterates over the files in the category to make
    # it super easy to code loops.
    $s->good_files->do->modify;

    # Run some methods on files classified as "bad"
    $s->bad_files->do->fix;
    $s->bad_files->do->modify;

    # You can call methods not in the current class as long as they are defined
    # in one of your parent Processor classes.
    $s->good_files->do->move;
    $s->bad_files->do->move;
  }

Now create the Processor class to contain the methods needed to  processing the
files or data.

  use File::Collector::YourClassifier::Processor;
  use parent File::Collector::Processor;

  # This method is run once for each file
  sub modify {
    my $s = shift;

    # skip the file if it has already been processed
    next if ($s->attr_defined ( 'data', 'processed' ));

    # properties of objects from previous Classifiers can be easily accessed
    my @values = $s->get_obj_prop ( 'header', 'needed_values' );

    # You can easily run methods on objects here, too. Here we run the
    # copy_file() method on the data object and pass it
    # some values.
    $s->obj_meth ( 'data', 'copy_file', \@values );
  }

  # Code for fixing "bad" files goes here.
  sub fix {
    ...
  }

Now that your classes have been created, you can classify and process the files:

   my $collector = File::Collector::YourClassifier->new('my/dir');

   # The $collector object has useful methods
   $collector->get_count; # returns total number of files in the collection

   # Some behind-the-scenes magic is employed to make it painless to iterate
   # over files and run methods on them.
   while ($collector->next_good_files) {
     $collector->print_short_name;
   }


=head1 DESCRIPTION

=method method1()



=method method2()



=func function1()



=func function2()



=attr attribute1



=attr attribute2



#=head1 CONFIGURATION AND ENVIRONMENT
#
#{{$name}} requires no configuration files or environment variables.


=head1 DEPENDENCIES

=head1 AUTHOR NOTES

=head2 Development status

This module is currently in the beta stages and is actively supported and maintained. Suggestion for improvement are welcome.

- Note possible future roadmap items.

=head2 Motivation

Provide motivation for writing the module here.

#=head1 SEE ALSO
