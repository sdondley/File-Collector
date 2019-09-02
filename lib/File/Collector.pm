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

  if (!$s->{_files}{"$2_files"}) { $s->_scroak("No such file category exists: '$2' at "); }
  else { return $s->{_files}{"$2_files"} if !$1; }

  if ($1 eq 'next_') {
    return $s->{_files}{"$2_files"}->next;
  }

  if ($1 eq 'isa_') {
    return $s->{_files}{"$2_files"}->isa;
  }

  if ($1 eq 'get_') {
    return values %{$s->{_files}{"$2_files"}{_files}};
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
    _files          => { all => {} },
    _common_dir     => '',
    selected        => '',
    _options        => \%opts,
  }, $class;

  $s->{all} = $s->{_files}{all};

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
  foreach my $file (@{$s->{_files}{new}}) {
    $s->{selected} = $file;
    $s->_classify_file;
  }
  $s->_run_processes;
  undef $s->{selected};
  undef $s->{_files}{new};                 # clear the new_file array
}

sub get_count {
  my $s = shift;
  return (scalar keys %{$s->{_files}{all}})
}

sub get_files {
  my $s = shift;

  my @files = sort keys %{$s->{_files}{all}};
  return @files;
}

sub get_file {
  my ($s, $file) = @_;
  $s->_scroak('No file argument passed to method. Aborting.') if !$file;

  return $s->{_files}{all}{$file};
}

sub list_files_long {
  my $s = shift;

  my @files = $s->get_files;
  print $_ . "\n" for @files;
}

sub list_files {
  my $s = shift;

  my @files = map { $s->{_files}{all}{$_}{short_path} } sort keys %{$s->{_files}{all}};
  print "\nFiles found in '".$s->{_common_dir}."':\n\n";
  print $_ . "\n" for @files;
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
    next if ($s->{_files}{"${it}_files"});    # don't overwrite existing processor
    $s->{_files}{"${it}_files"} = $it_class->new($s->{_files}{all}, \($s->{selected}));
  }
}

sub _classify {
  my ($s, $type) = @_;
  my $file = $s->selected;
  my $t = $type . '_files';

  # die if bad args given
  $s->_croak("No $type argument sent to _classify method. Aborting.") if !$type;
  $s->_croak("No processor called $type exists. Aborting.") if !$s->{_files}{$t};

  $s->{_files}{$t}->_add_file($file, $s->{_files}{all}{$file});
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

  $s->{_common_dir} = $longest_string || (fileparse($file))[1];

  if (@files) {
    foreach my $file ( @files, $file ) {
      $s->{_files}{all}{$file}{short_path} = $file =~ s/$longest_string//r;
    }
  } else {
    $s->{_files}{all}{$file}{short_path} = $file;
  }
}

sub _add_file {
  my ($s, $file) = @_;

  $file                                 = $s->_make_absolute($file);
  $s->{_files}{all}{$file}{full_path}   = $file;
  my $filename                          = (fileparse($file))[0];
  $s->{_files}{all}{$file}{filename}    = $filename;

  push @{$s->{_files}{new}}, $file if !$s->{_files}{$file};
}

sub _add_obj {
  my ($s, $type, $obj) = @_;
  $s->_scroak("Missing args to 'add_obj' method. Aborting.") if (!$type || !$obj);

  $s->{_files}{all}{$s->selected}{"${type}_obj"} = $obj;
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

  my @dirs  = grep { -d "$dir/$_" } @dirs_and_files if $s->{_options}{recurse};
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

