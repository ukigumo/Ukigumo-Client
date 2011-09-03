use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Perl;
use Mouse;
use Ukigumo::Constants;

sub run {
    my ($self, $c) = @_;

    if (-f 'Makefile.PL') {
        $c->tee("perl Makefile.PL 2>&1")==0 or return STATUS_FAIL;
        $c->tee("make test 2>&1")==0 or return STATUS_FAIL;
        return STATUS_SUCCESS;
    } elsif (-f 'Build.PL') {
        $c->tee("perl Build.PL 2>&1")==0 or return STATUS_FAIL;
        $c->tee("./Build test 2>&1")==0 or return STATUS_FAIL;
        return STATUS_SUCCESS;
    } else {
        $c->log("There is no Makefile.PL or Build.PL");
        return STATUS_NA;
    }
}

1;

