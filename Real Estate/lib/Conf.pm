package Conf;

use strict;

require "./settings.conf"; # GLOBAL settings hash

our %GLOBAL;

sub new {
    my $class = shift;
    my $self = bless \%GLOBAL, $class;
    return $self;
}

1;
