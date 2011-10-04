#!/usr/local/bin/perl
use strict;
use warnings;
use utf8;
use 5.008008;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '..', 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), '..', 'lib');

package main;
use Getopt::Long;
use Pod::Usage;

use Ukigumo::Client;
use Ukigumo::Client::VC::Git;
use Ukigumo::Client::Executor::Auto;
use Ukigumo::Client::Notify::Debug;
use Ukigumo::Client::Notify::Ikachan;

GetOptions(
    'branch=s'          => \my $branch,
    'workdir=s'         => \my $workdir,
    'repo=s'            => \my $repo,
    'ikachan_url=s'     => \my $ikachan_url,
    'ikachan_channel=s' => \my $ikachan_channel,
    'server_url=s'      => \my $server_url,
    'project=s'         => \my $project,
);
$repo       or do { warn "Missing mandatory option: --repo\n\n"; pod2usage() };
$server_url or do { warn "Missing mandatory option: --server_url\n\n"; pod2usage() };
$branch='master' unless $branch;
die "Bad branch name: $branch" unless $branch =~ m{^[A-Za-z0-9./_-]+$}; # guard from web
$server_url =~ s!/$!! if defined $server_url;

my $app = Ukigumo::Client->new(
    (defined($workdir) ? (workdir => $workdir) : ()),
    vc   => Ukigumo::Client::VC::Git->new(
        branch     => $branch,
        repository => $repo,
    ),
    executor   => Ukigumo::Client::Executor::Perl->new(),
    server_url => $server_url,
    ($project ? (project    => $project) : ()),
);
#$app->push_notifier( Ukigumo::Client::Notify::Debug->new());
if ($ikachan_url) {
    if (!$ikachan_channel) {
        warn "You specified ikachan_url but ikachan_channel is not provided\n\n";
        pod2usage();
    }
    $app->push_notifier(
        Ukigumo::Client::Notify::Ikachan->new(
            url     => $ikachan_url,
            channel => $ikachan_channel,
        )
    );
}
$app->run();
exit 0;

__END__

=head1 NAME

ukigumo-client.pl - ukigumo client script

=head1 SYNOPSIS

    % ukigumo-client.pl --repo=git://...
    % ukigumo-client.pl --repo=git://... --branch foo

        --repo=s            URL for git repository
        --workdir=s         workdir directory for working(optional)
        --branch=s          branch name('master' by default)
        --server_url=s      Ukigumo server url(using app.psgi)
        --ikachan_url=s     API endpoint URL for ikachan
        --ikachan_channel=s channel to post message

=head1 DESCRIPTION

This is a yet another continuous testing tools.

=head1 EXAMPLE

    perl bin/ukigumo-client.pl --server_url=http://localhost:9044/ --repo=git://github.com/tokuhirom/Acme-Failing.git --branch=master

Or use online demo.

    perl bin/ukigumo-client.pl --server_url=http://ukigumo-4z7a3pfx.dotcloud.com/ --repo=git://github.com/tokuhirom/Acme-Failing.git

=head1 SEE ALSO

L<https://github.com/yappo/p5-App-Ikachan>

=cut
