use strict;
use warnings;
use Ukigumo::Client::EnvVar;
use Test::More;

subtest 'Set and restore environment variables' => sub {
    subtest 'scalar env' => sub {
        my $orig_env_foo = $ENV{foo};
        my $orig_env_buz = $ENV{buz};

        my $env_var = Ukigumo::Client::EnvVar->new;
        $env_var->set({env => 'foo=bar buz=qux foo=hoge'});
        is $ENV{foo}, 'hoge';
        is $ENV{buz}, 'qux';

        $env_var->restore;
        is $ENV{foo}, $orig_env_foo;
        is $ENV{buz}, $orig_env_buz;
    };

    subtest 'array ref' => sub {
        my $orig_env_foo = $ENV{foo};
        my $orig_env_buz = $ENV{buz};

        my $env_var = Ukigumo::Client::EnvVar->new;
        $env_var->set({env => ['foo=bar', 'buz=qux', 'foo=hoge']});
        is $ENV{foo}, 'hoge';
        is $ENV{buz}, 'qux';

        $env_var->restore;
        is $ENV{foo}, $orig_env_foo;
        is $ENV{buz}, $orig_env_buz;
    };
};

done_testing;

