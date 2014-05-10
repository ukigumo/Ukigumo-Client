package Ukigumo::Client::Logger;
use strict;
use warnings;
use utf8;
use Ukigumo::Logger;

use Mouse;

has logfh => (
    is       => 'ro',
    required => 1,
);

has branch => (
    is       => 'ro',
    required => 1,
);

has quiet => (
    is       => 'ro',
    required => 1,
);

has _logger => (
    is => 'ro',
    isa => 'Ukigumo::Logger',
    default => sub {
        my $self = shift;
        Ukigumo::Logger->new(prefix => ['[' . $self->branch . ']']);
    },
);

has _format => (
    is => 'ro',
    default => sub {
        return sub {
            my ($time, $type, $message) = @_;
            warn "$time [$type] $message\n";
        };
    },
);

no Mouse;

sub infof {
    my $self = shift;

    my $STDERR = *STDERR;

    local *STDERR = $self->logfh;
    local $Log::Minimal::PRINT = $self->_format;

    $self->_logger->infof(@_);

    unless ($self->quiet) {
        *STDERR = $STDERR;
        $self->_logger->infof(@_);
    }
}

sub warnf {
    my $self = shift;

    my $STDERR = *STDERR;

    local *STDERR = $self->logfh;
    local $Log::Minimal::PRINT = $self->_format;

    $self->_logger->warnf(@_);

    unless ($self->quiet) {
        *STDERR = $STDERR;
        $self->_logger->warnf(@_);
    }
}

1;

