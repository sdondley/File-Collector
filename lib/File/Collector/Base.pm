package File::Collector::Base ;
use strict;
use warnings;

use Carp;
use File::Basename;
use Log::Log4perl::Shortcuts       qw(:all);

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
    _scroak ("Non-existent $obj object attribute requested: '$prop'");
  }
  my $value = $object->{$attr};
  if (ref $value eq 'ARRAY') {
    return @$value;
  } else {
    return $value;
  }
}

sub short_name {
  my $s    = shift;
  my $file = ref ($s->selected) eq 'HASH'
             ? $s->selected->{full_path}
             : $s->selected;
  $s->{all}{$file}{short_path};
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
  logd \@_;
  return $obj->$meth($s->short_name, @_);
}

sub selected {
  (shift)->{selected}
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

sub _exists {
  my $s = shift;
  $s->_scroak("'$_[0]' does not exist, aborting call from: ") if ! -e $_[0];
}

sub _scroak {
  my $s = shift;
  my $msg = shift;
  croak($msg . ' ' . (fileparse((caller(1))[1]))[0] . ', line ' . (caller(1))[2] . "\n");
}



1; # Magic true value
# ABSTRACT: this is what the module does


__END__

=head1 OVERVIEW

Provide overview of who the intended audience is for the module and why it's useful.

=head1 SYNOPSIS

  use {{$name}};

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
