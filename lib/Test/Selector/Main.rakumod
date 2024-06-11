unit class Test::Selector::Main:ver<0.3.1>:auth<zef:lucs>;

use Path::Finder;

proto sub MAIN (|) is export(:MAIN) {*}

multi sub MAIN (
    Str  $blocks-glob = '*',
    Str  :f($files-prefix) = '',
    Str  :t($test-dirs),
    Str  :ti($also-test-dirs),
    Str  :r($lib-dirs),
    Str  :ri($also-lib-dirs),
    Bool :q($quiet) = False,
    Bool :qq($very-quiet) = False,
    Bool :l($list) = False,
    Bool :v($version) = False,
    Bool :h($help)  = False,
) {

    if $help {
        say q:to/EoH/
            Example invocations:
                ▸ tsel -f=02 a\*  # Asterisk escaped, else the shell will expand it.
                ▸ tsel -ri=../other-module/lib -q

            Command line arguments:

                Type Argument Default Description
                ---- -------- ------- -----------
                Str  <blocks> '*'     Block labels matching this glob, like 'a*'.
                Str  -f       ''      Files starting with this prefix, like '02'.
                Bool -q       False   Quiet output.
                Bool -qq      False   Quieter output.
                Bool -l       False   List matching block labels and exit 0.
                Bool -v       False   Show version and exit 0.
                Bool -h       False   Show this message and exit 0.

            Test files to use must be named *.rakutest, *.t, or *.t6
            and must reside in ./t/ or in one of these comma separated dirs:

                Str  -t  <test dirs>        These dirs.
                Str  -ti <also test dirs>   ./t/, then these.

            RAKULIB will use ./lib/ or one of these comma separated dirs:

                Str  -r  <lib dirs>         These dirs.
                Str  -ri <also lib dirs>    ./lib/, then these.
            EoH
        ;
        exit 0;
    }

    if $version {
        say "Test::Selector {Test::Selector::Main.^ver} on $*RAKU.compiler.gist().";
        exit 0;
    }
    sub test-file ($f, $action, $quiet) {
        say "# {$action eq 'run' ?? 'Testing' !! 'Labels in'} $f:";
        my $proc = Proc::Async.new: :w, $*EXECUTABLE, $f;

        react {
            whenever $proc.stdout.lines {
                next if (
                    / ^ \s* ok \ / ||
                    / ^ '# Subtest: ' /
                ) && ($quiet || $very-quiet);
                next if (
                    / ^ \s* '# ' /
                ) && $very-quiet;
                say $_;
            }
            whenever $proc.stderr.lines {
                say $_;
            }
            whenever $proc.start {
                done;
            }
        }
    }

        # If for some reason RAKULIB is already set, we will change it
        # only by prepending to it.
    sub prepend-to-rakulib ($dirs) {
        %*ENV<RAKULIB> = %*ENV<RAKULIB>
            ?? "$dirs," ~ %*ENV<RAKULIB>
            !! $dirs
        ;
    }

        # Set up RAKULIB.
    if $lib-dirs {
        if $also-lib-dirs {
            note "At most one of the -r of -ri options can be used.";
            exit 1;
        }
        prepend-to-rakulib $lib-dirs;
    }
    elsif $also-lib-dirs {
        prepend-to-rakulib "$*CWD/lib,$also-lib-dirs"
    }
    else {
        prepend-to-rakulib "$*CWD/lib";
    }

        # Set up the test directories.
    my $t-dirs;
    if $test-dirs {
        if $also-test-dirs {
            note "At most one of the -t of -ti options can be used.";
            exit 1;
        }
        $t-dirs = $test-dirs;
    }
    elsif $also-test-dirs {
        $t-dirs = "$*CWD/t,$also-test-dirs";
    }
    else {
        $t-dirs = "$*CWD/t";
    }

        # Set up other required envvars.
    %*ENV<TEST_SELECTOR_BLOCKS_LABEL_PATTERN> = $blocks-glob;

    my $action = $list ?? 'list' !! 'run';
    %*ENV<TEST_SELECTOR_ACTION> = $action;

        # Run the blocks in the matching files.
    my $rule = Path::Finder.or(
        Path::Finder.name("$files-prefix*.rakutest"),
        Path::Finder.name("$files-prefix*.t"),
        Path::Finder.name("$files-prefix*.t6"),
    );

    for $rule.in("$t-dirs".split: ',') -> $f {
        test-file $f, $action, $quiet;
    }

}

