package Ukigumo::Client::Notify::Webhook;
use strict;
use warnings;
use utf8;

use Mouse;
use Ukigumo::Constants;
use Ukigumo::Helper qw(status_str);

has 'url' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has form => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} },
);

has headers => (
    is => 'ro',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} },
);

has 'ignore_success' => (
    is => 'ro',
    isa => 'Bool',
    required => 0,
    default => 1,
);

has ignore_skip => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

no Mouse;

sub send {
    my $self = shift;
    my $context = \@_;
    my ($c, $status, $last_status, $report_url, $current_revision) = @_;

    if ( $self->ignore_success && $status eq STATUS_SUCCESS && defined($last_status) && ($last_status eq STATUS_SUCCESS || $last_status eq STATUS_SKIP) ) {
        $c->logger->infof(
            "The test was succeeded. There is no reason to notify($status, $last_status).");
        return;
    }
    if ( $self->ignore_skip && $status eq STATUS_SKIP ) {
        $c->logger->infof( "The test was skiped. There is no reason to notify.");
        return;
    }

    my $form = $self->__render($context, $self->form);
    my $headers = $self->__render($context, $self->headers);

    my $ua = $c->user_agent();
    my $res = $ua->post(
        $self->url,
        $form,
        %$headers,
    );

    if ( $res->is_success ) {
        $c->logger->infof("Sucessfully sent notification to webhook: " . $self->url);
    } else {
        die "Failed to post notification webhook: " . join(' ', 'notice', $self->url, $res->status_line );
    }
}

sub __render {
    my ($self, $context, $h) = @_;

    my %keywords = (
        project          => sub { $context->[0]->project },
        branch           => sub { $context->[0]->branch },
        status           => sub { $context->[1] },
        last_status      => sub { $context->[2] },
        report_url       => sub { $context->[3] },
        current_revision => sub { $context->[4] },
    );

    my %h2;
    my $re = '(?:' . join('|', keys %keywords) . ')';
    for my $k (keys %$h) {
        my $v = $h->{$k};
        $k =~ s/\{\{ ($re) \}\}/ $keywords{$1}->() /exg;
        $v =~ s/\{\{ ($re) \}\}/ $keywords{$1}->() /exg;
        $h2{$k} = $v;
    }
    return \%h2;
}

1;

=head1 NAME

Ukigumo::Client::Notify::Webhook - send notification to a http server.

=head1 DESCRIPTION

This is a notifier class for Ukigumo.

=head1 ATTRIBUTES

=over 4

=item url (Str)

URL of the server that can handle this post message.

=item headers (HashRef)

Custom HTTP headers.

=item form (HashRef)

Form content.

=item ignore_skip (Bool)

Ignore the message if it's skipped.

=item ignore_success (Bool)

Ignore the message if it's succeeded.

=back

