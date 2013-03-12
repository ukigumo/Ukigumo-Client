package Ukigumo::Client;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.13';

use Carp ();
use Capture::Tiny;
use Encode::Locale;
use Encode;
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
use URI::Escape qw(uri_escape);
use YAML::Tiny;

use Ukigumo::Constants;

use Mouse;

has 'workdir' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        File::Spec->catdir( File::HomeDir->my_home, '.ukigumo', 'work')
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
has 'user_agent' => (
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $ua = LWP::UserAgent->new(
            agent => "ukigumo-client/$Ukigumo::Client::VERSION" );
        $ua->env_proxy;
        $ua;
    },
);

has quiet => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
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

    my $workdir = File::Spec->catdir( $self->workdir, uri_escape($self->project), uri_escape($self->branch) );

    $self->log("ukigumo-client $VERSION");
    $self->log("start testing : " . $self->vc->description());
    $self->log("working directory : " . $workdir);

    {
        mkpath($workdir);
        chdir($workdir) or die "Cannot chdir(@{[ $workdir ]}): $!";

		$self->log('run vc : ' . ref $self->vc);
        my $orig_revision = $self->vc->get_revision();
        $self->vc->update($self, $workdir);
        my $current_revision = $self->vc->get_revision();

        if ($self->vc->skip_if_unmodified && $orig_revision eq $current_revision) {
            $self->log('skip testing');
            return;
        }
        my $vc_log = $self->vc->get_log($orig_revision, $current_revision);

        my $conf = $self->load_config();

        $self->run_commands($conf, 'before_install');

        $self->install($conf);

        $self->run_commands($conf, 'before_script');

        my $executor = defined($conf->{script}) ? Ukigumo::Client::Executor::Command->new(command => $conf->{script}) : $self->executor;

		$self->log('run executor : ' . ref $executor);
        my $status = $executor->run($self);

		$self->log('finished testing : ' . $status);

        $self->run_commands($conf, 'after_script');

        my ($report_url, $last_status) = $self->send_to_server(
            $status, $current_revision, $vc_log
        );

        $self->log("sending notification: @{[ $self->branch ]}, $status");
        $self->_load_notifications($conf);
        for my $notify (@{$self->notifiers}) {
            $notify->send($self, $status, $last_status, $report_url);
        }
    }

    $self->log("end testing");
}

sub _load_notifications {
    my ($self, $conf) = @_;
    for my $type (keys %{$conf->{notifications}}) {
        if ($type eq 'ikachan') {
            my $c = $conf->{notifications}->{$type};
               $c = [$c] unless ref $c eq 'ARRAY';

            for my $args (@$c) {
                my $notifier = Ukigumo::Client::Notify::Ikachan->new($args);
                push @{$self->{notifiers}}, $notifier;
            }
        } else {
            die "Unknown notification type: $type";
        }
    }
}

sub load_config {
    my $self = shift;

    if ( -e '.ukigumo.yml' ) {
        my $y = eval { YAML::Tiny->read('.ukigumo.yml') };
        $self->log("Bad .ukigumo.yml: $@") if $@;
        $y ? $y->[0] : undef;
    }
    else {
        $self->log("There is no .ukigumo.yml");
        undef;
    }
}

# Install deps
sub install {
    my ($self, $conf) = @_;

    my $install = do {
        if ($conf->{install}) {
            $conf->{install};
        } else {
            if (-f 'Makefile.PL' || -f 'cpanfile' || -f 'Build.PL') {
                'cpanm --notest --installdeps .';
            } else {
                undef;
            }
        }
    };
    if ($install) {
        $self->log("[install] $install");
        system($install)
            == 0 or die "Failure in installing: $install";
    }
}

sub run_commands {
    my ($self, $yml, $phase) = @_;
    for my $cmd (@{$yml->{$phase} || []}) {
        $self->log("[${phase}] $cmd");
        system($cmd)
            == 0 or die "Failure in ${phase}: $cmd";
    }
}

sub send_to_server {
    my ($self, $status, $current_revision, $vc_log) = @_;

	my $ua = $self->user_agent();

    # flush log file before send it
    $self->logfh->flush();

    my $server_url = $self->server_url;
       $server_url =~ s!/$!!g;
	my $req = 
		POST $server_url . '/api/v1/report/add',
		Content_Type => 'form-data',
		Content => [
			project  => $self->project,
			branch   => $self->branch,
			repo     => $self->repository,
			revision => $current_revision,
			status   => $status,
            vc_log   => $vc_log,
			body     => [$self->logfh->filename],
		];
	my $res = $ua->request($req);
	$res->is_success or die "Cannot send a report to @{[ $self->server_url ]}/api/v1/report/add:\n" . $res->as_string;
	my $dat = eval { decode_json($res->decoded_content) } || $res->decoded_content . " : $@";
	$self->log("report url: $dat->{report}->{url}");
	my $report_url = $dat->{report}->{url} or die "Cannot get report url";
    return ($report_url, $dat->{report}->{last_status});
}


sub tee {
    my ($self, $command) = @_;
    $self->log("command: $command");
    my ($out) = Capture::Tiny::tee_merged {
        ( $EUID, $EGID ) = ( $UID, $GID );
        system $command
    };
    $out = Encode::encode("console_in", Encode::decode("console_out", $out));

    print {$self->logfh} $out;
    return $?;
}

sub log {
    my $self = shift;
    my $msg = join( ' ',
        Time::Piece->new()->strftime('[%Y-%m-%d %H:%M]'),
        '[' . $self->branch . ']', @_ )
      . "\n";
	print STDOUT $msg unless $self->quiet;
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

=head1 ATTRIBUTES

=over 4

=item workdir

Working directory for the code. It's $ENV{HOME}/.ukigumo/work/$project/$branch by default.

=item project

Its' project name. This is a mandatory parameter.

=item logfh

Log file handle. It's read only parameter.

=item server_url

URL of the Ukigumo server. It's required.

=item user_agent

instance of L<LWP::UserAgent>. It's have a default value.

=item vc

This is a version controller object. It's normally Ukigumo::Client::VC::*. But you can write your own class.

VC::* objects should have a following methods:

    get_revision branch repository

=item executor

This is a test executor object. It's normally Ukigumo::Client::Executor::*. But you can write your own class.

=item notifiers

This is a arrayref of notifier object. It's normally Ukigumo::Client::Notify::*. But you can write your own class.

=back

=head1 METHODS

=over 4

=item $client->push_notifier($notifier : Ukigumo::Client::Notify)

push a notifier object to $client->notifiers.

=item $client->run()

Run a test context.

=item $client->send_to_server($status: Int)

Send a notification to the sever.

=item $client->tee($command: Str)

This method runs C<< $command >> and tee the output of the STDOUT/STDERR to the logfh.

I<Return>: exit code by the C<< $command >>.

=item $client->log($message)

Print C<< $message >> and write to the logfh.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Ukigumo::Server>, L<Ukigumo:https://github.com/ukigumo/>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
