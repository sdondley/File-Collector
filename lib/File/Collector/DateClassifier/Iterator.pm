package File::Collector::DateClassifier::Iterator ;
use strict;
use warnings;

use parent qw (File::Collector::Iterator);
use Log::Log4perl::Shortcuts       qw(:all);

sub print_blah_names {
  my $s = shift;
  print $s->next->{short_path} . "\n\n";
}

sub DESTROY {
  my $s = shift;
  $s->next;
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
