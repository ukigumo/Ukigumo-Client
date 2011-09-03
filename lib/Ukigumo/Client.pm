package Ukigumo::Client;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.01';

use Carp ();
use File::Spec;
use File::Path qw(mkpath);
use LWP::UserAgent;
use Time::Piece;
use English '-no_match_vars';
use File::Basename qw(dirname);
use HTTP::Request::Common qw(POST);
use JSON qw(decode_json);
use File::Temp;
use File::HomeDir;

use Ukigumo::Constants;

use Mouse;

has 'workdir' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        File::Spec->catdir( File::HomeDir->my_home, '.ukigumo', 'work',
            $self->project, $self->branch );
    },
);
has 'project' => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $proj = $self->repository;
           $proj =~ s/\.git$//;
           $proj =~ s!.+\/!!;
           $proj || '-';
    },
    lazy => 1,
);
has 'logfh' => (
    is => 'ro',
    lazy => 1,
    default => sub { File::Temp->new(UNLINK => 1) }
);
has 'server_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# components
has 'vc' => (
    is       => 'ro',
    required => 1,
    handles => [qw(get_revision branch repository)],
);
has 'executor' => (
    is       => 'ro',
    required => 1,
);
has 'notifiers' => (
    is       => 'rw',
    default  => sub { +[ ] },
);
sub push_notifier {
    my $self = shift;
    push @{$self->notifiers}, @_;
}


sub run {
    my $self = shift;

    $self->log("ukigumo-client $VERSION");
    $self->log("start testing : " . $self->vc->description());
    $self->log("working directory : " . $self->workdir);

    {
        mkpath($self->workdir);
        chdir($self->workdir) or die "Cannot chdir(@{[ $self->workdir ]}): $!";

		$self->log('run vc : ' . ref $self->vc);
        $self->vc->update($self, $self->workdir);
		$self->log('run executor : ' . ref $self->executor);
        my $status = $self->executor->run($self);
		$self->log('finished testing : ' . $status);

        my ($report_url, $last_status) = $self->send_to_server($status);

        $self->log("sending notification: @{[ $self->branch ]}, $status");
        for my $notify (@{$self->notifiers}) {
            $notify->send($self, $status, $last_status, $report_url);
        }
    }

    $self->log("end testing");
}

sub send_to_server {
    my ($self, $status) = @_;

	my $ua = $self->get_user_agent();

	my $req = 
		POST $self->server_url . '/api/v1/report/add',
		Content_Type => 'form-data',
		Content => [
			project  => $self->project,
			branch   => $self->branch,
			repo     => $self->repository,
			revision => $self->vc->get_revision,
			status   => $status,
			body     => [$self->logfh->filename],
		];
	my $res = $ua->request($req);
	$res->is_success or die $res->as_string;
	my $dat = eval { decode_json($res->decoded_content) } || $res->decoded_content . " : $@";
	$self->log("report url: $dat->{report}->{url}");
	my $report_url = $dat->{report}->{url} or die "Cannot get report url";
    return ($report_url, $dat->{report}->{last_status});
}

sub get_user_agent {
    my $self = shift;

    return $self->{user_agent} ||=
      LWP::UserAgent->new(
        agent => "ukigumo-client/$Ukigumo::Client::VERSION" );
}

sub tee {
	my ($self, $command) = @_;
    $self->log("command: $command");
	my $pid = open(my $fh, '-|');
	local $SIG{PIPE} = sub { die "whoops, $command pipe broke" };

    if ($pid) {    # parent
        while (<$fh>) {
            print $_;
			print {$self->logfh} $_;
        }
        close($fh) || warn "kid exited $?";
		return $?;
    }
    else {         # child
        ( $EUID, $EGID ) = ( $UID, $GID );
        exec( $command );
        die "can't exec $command $!";
    }
}

sub file {
    my $self = shift;
    File::Spec->catfile($self->workdir, @_);
}

sub dir {
    my $self = shift;
    File::Spec->catdir($self->workdir, @_);
}

sub log {
    my $self = shift;
    my $msg = join( ' ',
        Time::Piece->new()->strftime('[%Y-%m-%d %H:%M]'),
        '[' . $self->branch . ']', @_ )
      . "\n";
	print STDOUT $msg;
	print {$self->logfh} $msg;
}


1;
__END__

=encoding utf8

=head1 NAME

Ukigumo::Client - Client library for Ukigumo

=head1 SYNOPSIS

    use Ukigumo::Client;
	use Ukigumo::Client::VC::Git;
	use Ukigumo::Client::Executor::Auto;
	use Ukigumo::Client::Notify::Debug;
	use Ukigumo::Client::Notify::Ikachan;

	my $app = Ukigumo::Client->new(
		vc   => Ukigumo::Client::VC::Git->new(
			branch     => $branch,
			repository => $repo,
		),
		executor   => Ukigumo::Client::Executor::Perl->new(),
		server_url => $server_url,
		project    => $project,
	);
	$app->push_notifier(
		Ukigumo::Client::Notify::Ikachan->new(
			url     => $ikachan_url,
			channel => $ikachan_channel,
		)
	);
	$app->run();

=head1 DESCRIPTION

Ukigumo::Client is client library for Ukigumo.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Ukigumo::Server>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
