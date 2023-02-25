unit class Test::Selector::Main;

use Path::Finder;
use IO::Glob;

proto sub MAIN (|) is export {*}

multi sub MAIN (
    $module-directory,
    :f($pfx) = '',
    :t($test_labels-glob) = '*',
    Bool :l($list) = False,
    Bool :q($quiet) = False,
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
    %*ENV<TEST_SELECTOR_LABELS_GLOB> = $test_labels-glob;
    %*ENV<TEST_SELECTOR_ACTION> = $list ?? 'list' !! 'run';
    %*ENV<RAKULIB> = %*ENV<RAKULIB>
        ?? "$module-directory/lib," ~ %*ENV<RAKULIB>
        !! "$module-directory/lib"
    ;

    my $rule = Path::Finder.or(
        Path::Finder.name("$pfx*.rakutest"),
        Path::Finder.name("$pfx*.t"),
    );

    for $rule.in("$module-directory/t") -> $f {
        say $f.path;
        test-file $f, $quiet;
    }

}

