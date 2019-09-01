package File::Collector ;
use strict; use warnings;

use Cwd;
use Carp;
use File::Basename;
use Log::Log4perl::Shortcuts qw(:all);

use parent 'File::Collector::Base';

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

sub get_count {
  my $s = shift;
  return (scalar keys %{$s->{files}{all}})
}

sub add_obj {
  my ($s, $type, $obj)     = @_;
  $s->_scroak("Missing args to 'add_obj' method. Aborting.") if (!$type || !$obj);
  $s->{files}{all}{$s->selected}{"${type}_obj"}    = $obj;
}

sub get_files {
  my $s = shift;

  my @files = sort keys %{$s->{files}{all}};
  return @files;
}

sub _init_processors {
  my $s = shift;
  $s->add_processors(@_);
}

sub add_processors {
  my $s = shift;
  my @processors = @_;

  my $class = ref($s);
  $class =~ s/::(\w)+$//;
  my $it_class = $class . '::Processor';
  foreach my $it ( @processors ) {
    next if $s->{files}{$it};            # don't overwrite existing processor
    $s->{files}{$it} = $it_class->new($s->{files}{all});
  }
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
  undef $s->{selected};
  undef $s->{files}{new_files};                 # clear the new_file array
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

sub _classify_file {
  return;
}

sub classify {
  my ($s, $type) = @_;
  my $file = $s->selected;
  $s->{files}{$type}->add_file($file, $s->{files}{all}{$file});
}

sub _add_file {
  my ($s, $file) = @_;

  $file                                 = $s->_make_absolute($file);
  $s->{files}{all}{$file}{full_path}    = $file;
  my $filename                          = (fileparse($file))[0];
  $s->{files}{all}{$file}{filename}     = $filename;

  push @{$s->{files}{new_files}}, $file if !$s->{files}{$file};
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

sub DESTROY {
}


1; # Magic true value
# ABSTRACT: Base classes for collecting and processing files in complex ways


__END__

=head1 OVERVIEW

C<File::Collector> and its companion module C<File::Collector::Processor> work
together to provide base classes for custom modules that classify and process
files and data related to the files.

For example, let's say you need to import raw files from one directory into some
kind of repository. Let's say that the content of the files needs to be parsed,
validated, rendered and/or changed before getting imported. Complicating things
further, let's say that the name and location of the file in the target
repository is dependent upon the content of the files in some way.

If this is a one-time operation, this can be accomplished with a series of
one-off scripts that process and import your files with each script producing
output suitable for the next script. But if such imports occur regularly or
involve a high level of complexity, running separate scripts for each processing
tage can be slow, tedious and error-prone.

The C<File::Collector> and C<File::Collector::Processor> base modules are
designed to help you create a chain of modules that can classify and process
files to suit your desires. These base modules will take out much of he tedium
that go into writing a series of discrete scripts to perform your task.

=head1 SYNOPSIS

  B<### A custom class for classifying files and setting up the processors>

  pakcage File::Collector::YourCustomFileValidator;
  use strict;
  use warnings;

  B<# The parent of this class is another File::Collector object.
  # This is how you chain Collectors and Processors together.>
  use parent File::Collector::YouCustomFileParser;

  # add the names of your custom processor here
  # processors must end with the string "_files"
  sub _init_processors {
    my $s = shift;
    $s->SUPER::_init_processors( @_, qw ( good_files bad_files ) );
  }

  # You can add this method to add file resources and run your
  # processes on them after they've been classified by the _classify_file
  # method
  sub add_resources {
    $s->SUPER::add_resources(@_);  # add new files and classify them

    # Run the modify_files() method on files classified as "good_files"
    $s->good_files->modify_files;
  }

  # This method is called once for each new file found
  # Use it to classify your files and create objects associated with the
  # files.
  sub _classify_file {
    my $s = shift;
    $s->SUPER::_classify_file;

    # create an object and pass the name of the file to it
    # $s->selcted contains the name of the file
    my $data = SomeObject->new( $s->selected );

    # associate the object with the file
    $s->add_obj('data', $data);

    # classify the file according to your criteria and add the
    # file to the appropriate processor

    if ( $data->{has_property} ) {
      $s->classify('good_files');
    } else {
      $s->classify('bad_files');
    }
  }

  ### Methods that process files or data associated found in this custom class

  # Provides useful methods for processing our files and data
  use parent File::Collector::Processor;

  sub modify_files_somehow {
    my $s = shift;

    # iterate over files found in the classification
    while ($s->next) {
      # skip the file if it has already been processed
      next if ($s->attr_defined ( 'data', 'processed' ));

      # properties of objects from previous Classifiers can be easily accessed
      my @values = $s->get_obj_prop ( 'header', 'needed_values' );

      # You can easily run methods on objects here, too. Here we run the
      # copy_file() method on the data object and pass it
      # some values.
      $s->obj_meth ( 'data', 'copy_file', \@values );
    }
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
