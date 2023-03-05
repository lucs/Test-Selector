unit class Test::Selector::Main;

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
    Bool :l($list) = False,
) {

    sub test-file ($f, $quiet) {
        say "# Testing $f …";
        my $proc = Proc::Async.new: :w, $*EXECUTABLE-NAME, $f;

        react {
            whenever $proc.stdout.lines {
                next if $quiet && (
                    / ^ \s* ok \ / ||
                    / ^ '# Subtest: ' /
                );
                say $_;
            }
            whenever $proc.stderr {
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
    %*ENV<TEST_SELECTOR_BLOCKS_GLOB> = $blocks-glob;
    %*ENV<TEST_SELECTOR_ACTION> = $list ?? 'list' !! 'run';

        # Run the blocks in the matching files.
    my $rule = Path::Finder.or(
        Path::Finder.name("$files-prefix*.rakutest"),
        Path::Finder.name("$files-prefix*.t"),
        Path::Finder.name("$files-prefix*.t6"),
    );

    for $rule.in("$t-dirs".split: ',') -> $f {
       # say $f.path;
        test-file $f, $quiet;
    }

}

