package Utils;

use strict;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}

sub trim {
    my ($self, $string) = @_;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}

1;
