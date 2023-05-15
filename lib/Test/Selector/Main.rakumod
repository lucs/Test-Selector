unit class Test::Selector::Main:ver<0.3.0>:auth<zef:lucs>;

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
            ⦃▸ tsel -f=02 -qq a42⦄ Arguments to ◆tsel are:
                Str  $blocks-glob   = '*'    Block labels matching this glob, ⦃a42⦄.
                Str  :f($files-pfx) = ''     Files starting with this prefix, ⦃02⦄.
                Bool :q($quiet)     = False  Quiet output.
                Bool :qq($quieter)  = False  Quieter output, ⦃-qq⦄.
                Bool :l($list)      = False  List block labels and exit 0.
                Bool :v($version)   = False  Show version and exit 0.
                Bool :h($help)      = False  Show this message and exit 0.

                    Test files in …<./t/> or in one of these.
                Str  :t($test-dirs)         In these dirs.
                Str  :ti($also-test-dirs)   In …<./t/>, then in these dirs.

                    .rakumod files in …<./lib/> or in one of these.
                Str  :r($lib-dirs)          In these dirs.
                Str  :ri($also-lib-dirs)    In …<./lib/>, then in these dirs.
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

