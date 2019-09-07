package File::Collector ;
use strict; use warnings;

use Cwd;
use Carp;
use File::Basename;
use Role::Tiny::With;
use Log::Log4perl::Shortcuts qw(:all);

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
    return $s->{_files}{"$2_files"}->_isa($s->selected);
  }

  if ($1 eq 'get_') {
    my $cat = $2;
    my $class = $s->{_processor_map}{$cat};
    my $obj = $class->new($s->{_files}{all},
              \($s->{selected}),
              $s->{_files}{"${cat}_files"}{_files});
    return $obj;
  }

  croak "No such method: $AUTOLOAD";
}

sub new {
  my $class = shift;

  # process args
  my ($user_opts, $classes, @resources) = _get_args(@_);

  # get options hash
  my $default_opts = { recurse => 1 };
  my %opts = (%$default_opts, %$user_opts);

  # construct object
  my $s = bless {
    _files          => { all => {} },
    _common_dir     => '',
    selected        => '',
    _options        => \%opts,
    _classes        => $classes,
    _roles          => undef,
    all             => undef,
  }, $class;

  # build roles
  foreach my $class ( @$classes ) {
    my $role = Role::Tiny->apply_roles_to_object ($s, $class);
    push @{ $s->{_roles} }, $role;
  }

  # a bit of trickery to make Processor class code consistent with base class
  $s->{all} = $s->{_files}{all};

  # add rersources and process files
  $s->add_resources(@resources);

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
  $s->_init_all_processors;
  foreach my $file (@{$s->{_files}{new}}) {
    $s->{selected} = $file;
    $s->_classify_all;
  }
  $s->_run_all;
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

# private methods meant for used by subclasses

sub _classify {
  my ($s, @classes) = @_;
  foreach my $type (@classes) {
    my $t = $type . '_files';
    my $file = $s->selected;

    # die if bad args given
    die ("No $type argument sent to _classify method. Aborting.") if !$type;
    die ("No processor called $type exists. Aborting.") if !$s->{_files}{$t};

    $s->{_files}{$t}->_add_file($file, $s->{_files}{all}{$file});
  }
}

sub _add_obj {
  my ($s, $type, $obj) = @_;
  $s->_scroak("Missing args to 'add_obj' method. Aborting.") if (!$type || !$obj);

  $s->{_files}{all}{$s->selected}{"${type}_obj"} = $obj;
}

# Methods for iterators

sub get_obj_prop {
  my ($s, $obj, $prop) = @_;

  if (!$prop || !$obj) {
    _scroak ("Missing arguments to get_obj_prop method");
  }

  my $file         = ref ($s->selected) eq 'HASH'
                     ? $s->selected->{full_path}
                     : $s->selected;
  my $attr         = "_$prop";
  my $o            = $obj . '_obj';
  my $object       = $s->{all}{$file}{$o};
  if (! exists $object->{$attr} ) {
    logd $attr;
    $s->_scroak ("Non-existent $obj object attribute requested: '_$prop'");
  }
  my $value = $object->{$attr};
  if (ref $value eq 'ARRAY') {
    return @$value;
  } else {
    return $value;
  }
}

sub get_obj {
  my ($s, $obj) = @_;

  if (!$obj) {
    _scroak ("Missing arguments to get_obj method");
  }

  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  my $o    = $obj . '_obj';

  return $s->{all}{$file}{$o};
}

sub set_obj_prop {
  my ($s, $obj, $prop, $val)  = @_;

  if (!$prop || !$obj) {
    $s->_scroak ("Missing arguments to set_obj_prop method");
  }

  my $file = $s->selected;

  my $o      = $obj . '_obj';
  my $object = $s->{all}{$file}{$o};
  my $attr   = "_$prop";
  if (! exists $object->{$attr} ) {
    $s->_scroak ("Non-existent $obj object attribute requested: '$prop'");
  }

  $object->{$attr} = $val;
}

sub get_filename {
  my $s = shift;
  my $file = $s->selected;

  return $s->{all}{$file}{filename};
}

sub obj_meth {
  # Keep these args shifted individually
  my $s    = shift;
  my $obj  = shift;
  my $meth = shift;
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;

  if (!$obj || !$meth) {
    _scroak ("Missing arguments to obj_meth method");
  }

  my $o            = $obj . '_obj';
  $obj             = $s->{all}{$file}{$o};

  if (! $obj->can($meth)) {
    _scroak ("Non-existent method on $obj object: '$meth'");
  }
  return $obj->$meth($s->_short_name, @_);
}

sub selected {
  my $s = shift;
  $s->{selected};
}

sub has_obj {
  my ($s, $type) = @_;

  if (!$type) {
    _scroak ("Missing argument to has method");
  }

  my $to   = "${type}_obj";
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  return defined $s->{all}{$file}{$to};
}

sub attr_defined {
  my $s = shift;
  my $obj = shift;
  my $attr = shift;
  return defined $s->selected->{"${obj}_obj"}->{"_${attr}"};
}

sub print_short_name {
  my $s = shift;

  $s->_scroak ("The 'print_short_name' method does not accept methods") if @_;
  print $s->_short_name . "\n";
}

# private helper methods

sub _short_name {
  my $s    = shift;
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  $s->{all}{$file}{short_path};
}

sub _exists {
  my $s = shift;
  $s->_scroak("'$_[0]' does not exist, aborting call from: ") if ! -e $_[0];
}

sub _scroak {
  my $s = shift;
  my $msg = shift;
  croak($msg . ' ' . (fileparse((caller(1))[1]))[0] . ', line ' . (caller(1))[2] . "\n");
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

sub _run_all {
  my $s = shift;
  my $classes = $s->{_classes};
  foreach my $c ( @$classes ) {
    my $role = Role::Tiny->apply_roles_to_object ($s, $c);
    $role->_run_processes if $role->can('_run_processes');;
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

sub _init_all_processors {
  my $s = shift;

  foreach my $c ( @{ $s->{_classes} } ) {
    my @processors = $c->_init_processors if $c->can('_init_processors');
    my $it_class = $c . '::Processor';
    foreach my $it ( @processors ) {
      next if ($s->{_files}{"${it}_files"});    # don't overwrite existing processor
      $s->{_processor_map}{$it} = $it_class;
      $s->{_files}{"${it}_files"} = $it_class->new($s->{_files}{all}, \($s->{selected}));
    }
  }
}

sub _classify_all {
  my $s = shift;
  foreach my $r ( @{ $s->{_roles} } ) {
#    logd $r;
    $r->_classify_file() if $r->can('_classify_file');;
  }
}

sub _get_args {
  my $user_opts = {};
  my @resources;
  my $classes;
  foreach my $arg (@_) {
    if (!ref $arg) {
      push @resources, $arg;
    } elsif (ref($arg) eq 'HASH') {
      croak ('Only one option hash allowed in constructor. Aborting.') if %$user_opts;
      $user_opts = $arg;
    } elsif (ref($arg) eq 'ARRAY') {
      die ('Only one class array allowed in constructor. Aborting.') if $classes;
      $classes = $arg;
    }
  }
  die('No list of resources passed to constructor. Aborting.') if ! @resources;
  #die('No Collector class array passed to constructor. Aborting.') if !$classes;

  return ($user_opts, $classes, @resources);
}

1; # Magic true value
# ABSTRACT: Collects files and sets up file Processors
