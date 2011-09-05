use strict;
use warnings;
use utf8;

package Ukigumo::Client::VC::Callback;
use Mouse;
use Cwd;

with 'Ukigumo::Client::Role::VC';

has 'revision_cb' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub { sub { 'unknown' } },
);

has 'update_cb' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

sub get_revision {
	my $self = shift;
	$self->revision_cb->(@_);
}

sub update {
    my ($self, $c) = @_;
	$self->update_cb->(@_);
}

1;

