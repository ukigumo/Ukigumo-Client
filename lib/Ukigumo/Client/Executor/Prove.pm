use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Prove;
use Mouse;
use Ukigumo::Constants;

sub run {
    my ($self, $c) = @_;
    return $c->tee("prove 2>&1")==0 ? STATUS_SUCCESS : STATUS_FAIL;
}

1;

