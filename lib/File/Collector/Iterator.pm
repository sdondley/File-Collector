package File::Collector::Iterator ;
use strict;
use warnings;

use Carp;
use Log::Log4perl::Shortcuts       qw(:all);

{
	my $collector;
	sub collector {
	    shift;
	    $collector = shift if @_;
	    return $collector;
	}
}

sub new {
  my $class = shift;
  $class->collector(shift);
  bless [@_], $class;
}

sub next {
  return shift @{(shift)};
}

sub print_short_names {
  my $s = shift;
  print short_name($s->next) . "\n";
}

sub selected_file { (shift)->[0]->{full_path} }

sub short_name { (shift)->{short_path} }

sub do {
  my $self = shift;
  bless \$self, 'File::Collector::Iterator::All';
}

{
  package File::Collector::Iterator::All;
  use Log::Log4perl::Shortcuts       qw(:all);
  sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my @method = split /::/, $AUTOLOAD;
    my $method = pop @method;
    $$self->$method(@_) while ($$self->selected_file);
  }
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
