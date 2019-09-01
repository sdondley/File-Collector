package File::Collector::Processor ;
use strict;
use warnings;

use Carp;
use Log::Log4perl::Shortcuts       qw(:all);

use parent 'File::Collector::Base';

sub new {
  my ($class, $all) = @_;

  bless { files => {}, iterator => [], all => $all, selected => '' }, $class;
}

sub next {
  my $s = shift;
  if (!$s->selected) {
    my @files = values %{$s->{files}};
    $s->{iterator} = \@files;
  }
  my $file               = shift @{$s->{iterator}};
  $s->{selected}         = $file;
  $s->{all}{selected}    = $file->{full_path};
}

sub isa {
  my $s    = shift;
  my $file = shift;

  defined $s->{files}{$file};
}

sub add_file {
  my ($s, $file, $data) = @_;
  $s->{files}{$file}    = $data; # add the file's data to processor
}

sub print_short_names {
  my $s = shift;
  while ($s->next) {
    print $s->selected->{short_path} . "\n";
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
