use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Command;
use Mouse;
use Ukigumo::Constants;

has command => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub run {
    my ($self, $c) = @_;
    return $c->tee($self->command)==0 ? STATUS_SUCCESS : STATUS_FAIL;
}

1;
__END__

=head1 NAME

Ukigumo::Client::Executor::Command - runs command

=head1 DESCRIPTION

This executor runs command.

