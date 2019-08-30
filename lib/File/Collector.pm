package File::Collector ;
use strict; use warnings;

use Cwd;
use Carp                           qw( croak cluck );
use File::Basename;
use Log::Log4perl::Shortcuts       qw(:all);

sub AUTOLOAD {
  our $AUTOLOAD;
  my $s = shift;
  $AUTOLOAD  =~ /.*::(\w+)$/ or
    croak "No such method: $AUTOLOAD";

  if (!$s->{files}{$1}) { croak 'No such file category exists: ' . $1; }
  else { return $s->{files}{$1}; }
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
    files          => {},
    common_dir     => '',
    options        => \%opts,
  }, $class;

  $s->add_resources(@_);
  return $s;
}

sub get_count {
  my $s = shift;
  return (scalar keys %{$s->{files}{all}})
}

sub obj_meth {
  my $s    = shift;
  my $obj  = shift;
  my $meth = shift;
  my $file = shift || $s->selected_file;

  if (!$obj || !$meth) {
    $s->_croak ("Missing arguments to obj_meth method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  my $o    = $obj . '_obj';
  $obj     = $s->{files}{$file}{$o};
  $meth    = "$meth";

  if (! $obj->can($meth)) {
    $s->croak ("Non-existent method on $obj object: '$meth'"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }
  return $obj->$meth($s->short_name, @_);
}

sub short_name {
  my $s = shift;
  my $file = shift;
  $s->{files}{$file}{short_path};
}

sub get_obj {
  my $s = shift;
  my $obj = shift;

  if (!$obj) {
    $s->_croak ("Missing arguments to get_obj method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  my $file = $s->{_iterator}->selected_file;
  my $o = $obj . '_obj';
  return $s->{files}{$file}{$o};

}

sub get_obj_prop {
  my $s    = shift;
  my $obj  = shift;
  my $prop = shift;
  my $file = shift || $s->selected_file;

  if (!$prop || !$obj || !$file) {
    $s->_croak ("Missing arguments to get_obj_prop method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  my $o = $obj . '_obj';
  my $object = $s->{files}{$file}{$o};
  my $attr = "_$prop";
  if (! exists $object->{$attr} ) {
    $s->croak ("Non-existent $obj object attribute requested: '$prop'"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }
  my $value = $object->{$attr};
  if (ref $value eq 'ARRAY') {
    return @$value;
  } else {
    return $value;
  }
}

sub set_obj_prop {
  my $s = shift;
  my $obj  = shift;
  my $prop = shift;
  my $val  = shift;

  if (!$prop || !$obj) {
    $s->croak ("Missing arguments to get_obj_prop method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  my $file = $s->selected_file;

  my $o = $obj . '_obj';
  my $object = $s->{files}{$file}{$o};
  my $attr = "_$prop";
  if (! exists $object->{$attr} ) {
    $s->croak ("Non-existent $obj object attribute requested: '$prop'"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }

  $object->{$attr} = $val;
}

sub add_obj {
  my ($s, $type, $obj)     = @_;
  my $ot                   = "${type}_obj";
  #$s->{files}{$type}{$file}{$ot} = $obj;
}

sub has_obj {
  my $s = shift;
  my $type = shift;

  if (!$type) {
    $s->croak ("Missing argument to has method"
      . ' at ' .  (caller(0))[1] . ', line ' . (caller(0))[2] );
  }
  my $file = shift || $s->selected_file;
  my $to = "${type}_obj";
  return defined $s->{files}{$file}{$to};
}

sub get_files {
  my $s = shift;

  my @files = sort keys %{$s->{files}{all}};
  return @files;
}

sub add_resources {
  my ($s, @resources) = @_;

  # collect the files
  foreach my $resource (@resources) {
    _exists($resource);
    $s->_add_file($resource)          if -f $resource;
    $s->_get_file_manifest($resource) if -d $resource;
  }

  $s->_generate_short_names;                    # calculate the short names
  $s->_classify_files($s->{files}{new_files});  # for subclass processing
  undef $s->{files}{new_files};                 # clear the new_file array
}

sub list_files_long {
  my $s = shift;

  my @files = $s->get_files;
  print $_ . "\n" for @files;
}

sub list_files {
  my $s = shift;

  my @files = map { $s->{files}{$_}{short_path} } sort keys %{$s->{files}};
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

sub get_filename {
  my $s = shift;
  my $file = $s->selected_file || shift;

  return $s->{files}{$file}{filename};
}

sub add_iterators {
  my $s = shift;
  my @iterators = @_;

  my $it_class = ref($s) . '::Iterator';
  foreach my $it ( @iterators ) {
    $s->{files}{$it} = $it_class->new();
  }

}

sub add_to_iterator {
  my $s    = shift;
  my $type = shift;
  my $file = shift;

  $s->{files}{$type}->add_file($s->{files}{all}{$file});
}

sub _add_file {
  my ($s, $file) = @_;

  $file = $s->_make_absolute($file);
  $s->{files}{all}{$file}{full_path} = $file;
  push @{$s->{files}{new_files}}, $file;
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

sub _exists {
  _croak("'$_[0]' does not exist, aborting call from: ") if ! -e $_[0];
}

sub _croak {
  my $msg = shift;
  croak($msg . (fileparse((caller(1))[1]))[0] . ', line ' . (caller(1))[2] . "\n");
}

sub DESTROY {
}

1; # Magic true value
# ABSTRACT: this is what the module does
