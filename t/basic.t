use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';

use Ukigumo::Client;
use Ukigumo::Client::VC::Callback;
use Ukigumo::Client::Executor::Callback;
use Ukigumo::Constants;
use JSON;

LWP::Protocol::PSGI->register(sub{
	ok 1;

	[200, ['Content-Type' => 'text/json'], [
		encode_json(+{
			report => {
				url => 'http://...',
			},
		})
	]];
});

my $client = Ukigumo::Client->new(
    vc => Ukigumo::Client::VC::Callback->new(
        update_cb  => sub { },
        branch     => 'master',
        repository => 'git:...',
    ),
    server_url => 'http://localhost/',
    executor   => Ukigumo::Client::Executor::Callback->new(
        run_cb => sub {
            return STATUS_NA;
        }
    ),
    quiet => 1,
);
$client->run();

done_testing;

