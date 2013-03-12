use strict;
use Module::Build::Pluggable qw(
    CPANfile
    GithubMeta
);

my $builder = Module::Build::Pluggable->new(
    license              => 'perl',
    dynamic_config       => 0,

    requires => {
        perl => '5.008005',
    },

    no_index    => { 'directory' => ['inc'] },
    name        => 'Ukigumo-Client',
    module_name => 'Ukigumo::Client',

    script_files         => ['bin/ukigumo-client.pl'],
    test_files           => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);
$builder->create_build_script();

