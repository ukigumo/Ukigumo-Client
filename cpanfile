requires 'LWP::UserAgent' => 6;
requires 'JSON' => 2;
requires 'Mouse' => 0;
requires 'File::HomeDir' => 0;
requires 'String::IRC' => 0;
requires 'Ukigumo::Common' => 0.03;
requires 'Time::Piece' => '1.15';
requires 'Capture::Tiny' => 0;
requires 'Encode::Locale' => 0;
requires 'URI::Escape' => 0;
requires 'Test::Requires' => 0;
requires 'YAML::Tiny' => 0;

on 'configure' => sub {
    requires 'Module::Build' => 0.40;
    requires 'Module::Build::Pluggable::GithubMeta';
};

