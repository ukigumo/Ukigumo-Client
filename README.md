Ukigumo-Client
==============

ukigumo-client is a cli client for ukigumo-server.

## Usage

    % ukigumo-client.pl --repo=git://github.com/nekokak/p5-Teng.git

        --workdir=s  working directory
                     (Default: ~/.ukigumo/work/)

## .ukigumo.yml

    before_install:
      - "cpanm Module::Install"
    notifications:
      ikachan:
        - channel: '#deadbeef'
          url: 'http://127.0.0.1:4979/'

ukigumo-client.pl supports YAML configurataion like [Travis CI](http://travis-ci.org/).
ukigumo-client supports part of .travis.yml detectives.

### before_install

Commands execute before install.

(Default: none)

### install

Commands *do* install.

(Default: 'cpanm --installdeps --notest .' if there is cpanfile, Makefile.PL, or Build.PL)

### after_install

Commands execute after install.

(Default: none)

### before_script

Commands execute before run test script.

(Default: none)

### script

Commands execute to run test script.

(Default: Run test case with Ukigumo::Client::Executor::Perl)

### after_script

Commands execute after run test script.

(Default: none)

### notifications

You can add configurations about notifications.

#### ikachan

    notifications:
      ikachan:
        - channel: '#deadbeef'
          url: 'http://127.0.0.1:4979/'

You can notify testing result to irc server by [ikachan](https://metacpan.org/release/App-Ikachan)

