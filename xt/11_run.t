use strict;
use warnings;
use utf8;
use Test::More;

is(system("$^X -wc bin/ukigumo-client.pl"), 0);

done_testing;

