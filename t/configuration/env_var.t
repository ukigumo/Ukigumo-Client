use strict;
use warnings;
use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Client::Executor::Callback;
use Test::More;

subtest 'Set environment variables' => sub {
    subtest 'basic' => sub {
        my $orig_env_foo = $ENV{foo};
        my $orig_env_buz = $ENV{buz};

        {
            local %ENV = %ENV;
            my $env_var = dispense_client()->_set_env_var({
                env => [
                    {foo => 'bar'},
                    {buz => 'qux'},
                    {foo => 'hoge'},
                ]
            });
            is $ENV{foo}, 'hoge';
            is $ENV{buz}, 'qux';
        }

        is $ENV{foo}, $orig_env_foo;
        is $ENV{buz}, $orig_env_buz;
    };

    subtest 'give not array ref' => sub {
        my $original__reflect_result = *Ukigumo::Client::_reflect_result{CODE};
        undef *Ukigumo::Client::_reflect_result;
        *Ukigumo::Client::_reflect_result = sub { }; # do nothing

        eval{my $env_var = dispense_client()->_set_env_var({env => 'waiwai'})};
        ok $@;

        undef *Ukigumo::Client::_reflect_result;
        *Ukigumo::Client::_reflect_result = $original__reflect_result;
    };
};

sub dispense_client {
    Ukigumo::Client->new(
        vc => Ukigumo::Client::VC::Callback->new(
            update_cb  => sub { },
            branch     => 'master',
            repository => 'git:...',
        ),
        server_url => 'http://localhost/',
        executor   => Ukigumo::Client::Executor::Callback->new(
            run_cb => sub { }
        ),
        workdir => '/tmp',
        quiet => 1,
    );
}

done_testing;

