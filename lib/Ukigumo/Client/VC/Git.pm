use strict;
use warnings;
use utf8;

package Ukigumo::Client::VC::Git;
use Mouse;
use Cwd;

with 'Ukigumo::Client::Role::VC';

has log_limit => ( is => 'ro', isa => 'Int', default => 50 );

sub default_branch { 'master' }

sub get_revision {
	my $self = shift;
	$self->{revision} ||= ( substr( `git rev-parse HEAD`, 0, 10 ) || 'Unknown' );
}

sub update {
    my ($self, $c) = @_;

    $c->log("workdir is " . Cwd::getcwd());
    unless (-d ".git") {
        $c->tee("git clone --branch $self->{branch} @{[ $self->repository ]} ./") == 0 or die "Cannot clone repository";
    }
    $c->tee("git pull -f origin $self->{branch}")==0 or die "git fail";
    $c->tee("git submodule init")==0 or die "git fail";
    $c->tee("git submodule update")==0 or die "git fail";
    $c->tee("git clean -dxf")==0 or die "git fail";
    $c->tee("git status")==0 or die "git fail";
    delete $self->{revision};
}

sub get_log {
    my ($self, $rev1, $rev2) = @_;
    # -50 means limit.
    `git log --pretty=format:"%h %an: %s" --abbrev-commit --source -@{[ $self->log_limit ]} '$rev1..$rev2'`
}

1;
__END__

=head1 NAME

Ukigumo::Client::VC::Git - git.

=head1 DESCRIPTION

This is a git wrapper for Ukigumo.

=head1 ATTRIBUTES

=over 4

=item repository

This is a repository URL.

=item branch

This is a name of branch. It's B<master> by default.

=back
