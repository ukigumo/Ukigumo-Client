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
$repo       or pod2usage();
$server_url or pod2usage();
$branch='master' unless $branch;
die "Bad branch name: $branch" unless $branch =~ /^[A-Za-z0-9._-]+$/; # guard from web
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
$app->push_notifier( Ukigumo::Client::Notify::Debug->new());
if ($ikachan_url) {
    pod2usage() if !$ikachan_channel;
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

=head1 SYNOPSIS

    % ukigumo-client --repo=git://... --workdir /path/to/workdir/dir
    % ukigumo-client --repo=git://... --workdir /path/to/workdir/dir --branch foo

        --repo=s            URL for git repository
        --workdir=s         workdir directory for working(optional)
        --branch=s          branch name('master' by default)
        --server_url=s      Ukigumo server url(using app.psgi)
        --ikachan_url=s     API endpoint URL for ikachan
        --ikachan_channel=s channel to post message

=head1 DESCRIPTION

超絶簡易的CIツール。 cron でよしなにぐるぐるまわして、fail したら mail とばす、で OK。

    MAILTO=ci@example.com
    */20 * * * * cronlog --timestamp -- ukigumo-client.pl --repo=git://github.com/ikebe/Pickles.git --branch switch_routes --base=/tmp/pickles-ci/

cronlog はこちらからインストールしてください: https://github.com/kazuho/kaztools

=head1 実行例

    perl bin/ukigumo-client.pl --server_url=http://localhost:9044/ --repo=git://github.com/tokuhirom/Acme-Failing.git

=head1 SEE ALSO

https://github.com/yappo/p5-App-Ikachan

=cut
