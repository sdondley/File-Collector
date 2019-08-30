package TestUtils 0.000001;

use vars qw(@ISA @EXPORT);

use Carp;
use Test::More;
@ISA = qw(Exporter);
@EXPORT = qw/ ref_check /;

sub ref_check {
  my $s = shift;
  my $checks = shift;

  subtest 'attribute tests' => sub {
    while (my ($attr, $type) = each %$checks) {
      is ref $s->{$attr}, $type,
        "Attribute '$attr' is $type";
    }
  };
}
