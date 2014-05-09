package Ukigumo::Client::EnvVar;
use strict;
use warnings;
use Parse::Yapp::KeyValue;

use Mouse;

has 'original' => (
    is  => 'rw',
    isa => 'HashRef',
);

no Mouse;

sub set {
    my ($self, $conf) = @_;

    my $kv = Parse::Yapp::KeyValue->new;

    my $env = $conf->{env};
    if ($env && ref $env ne 'ARRAY') {
        $env = [$env];
    }

    for my $e (@$env) {
        my $env_hash = $kv->parse($e);
        for my $key (keys %$env_hash) {
            $self->{original}->{$key} //= {value => $ENV{$key}};

            my $value = $env_hash->{$key};
            $ENV{$key} = ref $value eq 'ARRAY' ? $value->[-1] : $value;
        }
    }
}

sub restore {
    my ($self) = @_;

    my $original_env = $self->{original};
    for my $key (%{$original_env}) {
        $ENV{$key} = $original_env->{$key}->{value};
    }
}

1;

