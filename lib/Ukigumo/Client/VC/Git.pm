use strict;
use warnings;
use utf8;

package Ukigumo::Client::VC::Git;
use Mouse;
use Cwd;

has 'repository' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'branch' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub get_revision {
	my $self = shift;
	$self->{revision} ||= ( substr( `git rev-parse HEAD`, 0, 10 ) || 'Unknown' );
}

sub description {
    my $self = shift;
    return join(' ', $self->repository, $self->branch);
}

sub update {
    my ($self, $c) = @_;

    $c->log("workdir is " . Cwd::getcwd());
    unless (-d ".git") {
        $c->tee("git clone --branch $self->{branch} @{[ $self->repository ]} ./ 2>&1") == 0 or die "Cannot clone repository";
    }
    $c->tee("git pull -f origin $self->{branch} 2>&1")==0 or die "git fail";
    $c->tee("git submodule init 2>&1")==0 or die "git fail";
    $c->tee("git submodule update 2>&1")==0 or die "git fail";
    $c->tee("git clean -dxf 2>&1")==0 or die "git fail";
    $c->tee("git status 2>&1")==0 or die "git fail";
}

1;

