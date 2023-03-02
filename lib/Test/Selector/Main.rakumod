unit class Test::Selector::Main;

use Path::Finder;

proto sub MAIN (|) is export {*}

multi sub MAIN (
    Str  $blocks-glob = '*',
    Str  :f($files-prefix),
    Str  :t($test-dirs) = './t',
    Str  :ri($lib-dirs),
    Str  :r($rakulib),
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

        # Set up required envvars.
    %*ENV<TEST_SELECTOR_BLOCKS_GLOB> = $blocks-glob;
    %*ENV<TEST_SELECTOR_ACTION> = $list ?? 'list' !! 'run';
    %*ENV<RAKULIB> = %*ENV<RAKULIB>
        ?? "$module-directory/lib," ~ %*ENV<RAKULIB>
        !! "$module-directory/lib"
    ;

    my $rule = Path::Finder.or(
        Path::Finder.name("$files-prefix*.rakutest"),
        Path::Finder.name("$files-prefix*.t"),
        Path::Finder.name("$files-prefix*.t6"),
    );

    for $rule.in("$module-directory/t") -> $f {
        say $f.path;
        test-file $f, $quiet;
    }

}

