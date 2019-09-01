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
  $AUTOLOAD  =~ /.*::(next_|isa_)*(\w+)_files*$/ or
    croak "No such method: $AUTOLOAD";

  if (!$s->{files}{"$2_files"}) { $s->_scroak("No such file category exists: '$2' at "); }
  else { return $s->{files}{"$2_files"} if !$1; }

  if ($1 eq 'next_') {
    return $s->{files}{"$2_files"}->next;
  }

  if ($1 eq 'isa_') {
    return $s->{files}{"$2_files"}->isa;
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

sub set_obj_prop {
  my $s = shift;
  my $obj  = shift;
  my $prop = shift;
  my $val  = shift;

  if (!$prop || !$obj) {
    $s->_scroak ("Missing arguments to get_obj_prop method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  my $file = $s->selected_file;

  my $o = $obj . '_obj';
  my $object = $s->{files}{$file}{$o};
  my $attr = "_$prop";
  if (! exists $object->{$attr} ) {
    $s->_scroak ("Non-existent $obj object attribute requested: '$prop'"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  $object->{$attr} = $val;
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

sub get_filename { my $s = shift;
  my $file = $s->selected_file || shift;

  return $s->{files}{$file}{filename};
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

  $file = $s->_make_absolute($file);
  $s->{files}{all}{$file}{full_path} = $file;
  push @{$s->{files}{new_files}}, $file if !$s->{files}{$file};
  my $filename = (fileparse($file))[0];
  $s->{files}{all}{$file}{filename} = $filename;
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
# ABSTRACT: this is what the module does
