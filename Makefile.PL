use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Ukigumo-Client',
    AUTHOR        => 'Tokuhiro Matsuno <tokuhirom+cpan@gmail.com>',
    VERSION_FROM  => 'lib/Ukigumo/Client.pm',
    PREREQ_PM     => {
		'LWP::UserAgent' => 6,
		'JSON' => 2,
		'Mouse' => 0,
		'File::HomeDir' => 0,
		'String::IRC' => 0,
		'Ukigumo::Common' => 0.01,
		'Time::Piece' => '1.15',
		'Capture::Tiny' => 0,
		'Encode::Locale' => 0,
    },
    MIN_PERL_VERSION => '5.010000',
    (-d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING} || -d '.git') ? (
        test => {
            TESTS => 't/*.t xt/*.t',
        },
    ) : (),
	EXE_FILES => [ 'bin/ukigumo-client.pl' ]
);
