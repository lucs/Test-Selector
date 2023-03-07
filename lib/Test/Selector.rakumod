=begin pod

=head1 NAME

Test::Selector - Mark and selectively run only parts of test files

=head2 DESCRIPTION

During development of a module, you may want to run only one or more
of the tests in its test files to see how your code is coming along;
you may not yet care whether the other tests pass or not or you just
don't want to have to wait for them to finish.

The traditional way to run tests separately is to have them in
different files, but this can lead to having many of them and it might
be hard to find which ones are relevant at any point during
development.

With this module, you will be able to wrap into labeled blocks parts
of your test files and use the supplied ｢tsel｣ program to select which
of these blocks to run. It also lets you specify where to find the
test files and in which ones to look for the blocks. You can also
specify where to find other modules that may be required, but not yet
installed.

=head2 Labeled blocks

Given the following (uninteresting) original code from a test file:

    my $str = 'abc';
    ok(
        $str.chars == $str.flip.chars,
        "A reversed string is the same length as the original.",
    );

for the purpose of this module, you would wrap it like this with some
arbitrary label, here 's1':

    t s1 => {
        my $str = 'abc';
        ok(
            $str.chars == $str.flip.chars,
            "A reversed string is the same length as the original.",
        );
    }

｢t｣ is a subroutine exported by the module. It can be invoked in one
of the following example ways:

    t meep => { ⋯ }

    t $str => { ⋯ }

=head2 The 'tsel' program

By default, ｢tsel｣ expects you to run it from the root directory of
your module in development; that is, it expects to find there a ./t
subdirectory with the test files, and a ./lib subdirectory to which it
will set RAKULIB before running the tests.

Here are a few example invocations:

    cd ⟨Module directory⟩
    tsel s1
    tsel -f=04 s\*
    tsel -q ⋯
    tsel -l s\*
    tsel -ri=⋯/SomeModule/lib,/⋯/OtherModule/lib ⋯

    cd ⟨Arbitrary directory⟩
    tsel -t=⋯/MyModule/t -r=⋯/MyModule/lib,⋯/OtherModule/lib ⋯

｢tsel｣ has the following arguments:

    ⟨Blocks glob⟩ :

        Only blocks whose label matches the specified glob will be
        run. Recognized glob characters and what they match are:

            *    : any string, zero or more characters
            ?    : exactly one character
            […]  : characters from a set, for example ｢[abc]｣

        Default: ｢*｣

        Here are some examples, escaping the special glob characters
        to prevent them from being expanded by the shell, and labels
        they could match or not:

            n\*      Yes: n, n1, nything     No: an
            \[ab]\*c Yes: axc, a23c, bc      No: abcd, ebc
            a1\?     Yes: a11, a1x           No: a1, a1bc

    -f=⟨Files prefix⟩ :

        Only files whose extension is ｢.rakutest｣, ｢.t｣, or ｢.t6｣ and
        whose name starts with the specified prefix characters will be
        used.

        Default: all files with the proper extension will be used.

        Example:

            -f=04   Yes: 04-foo.rakutest, 04.t6  No: 04-bar.raku

    -t=⟨Use test files found in these comma separated directories⟩
    -ti=⟨Use test files found in ./t and in these comma separated directories⟩

        At most one of these options may be specified. If none is
        specified, test files will be searched for in ./t, the idea being
        that you will usually be running the program from the root of
        the module in development.

    -r=⟨Prepend to RAKULIB these comma separated directories⟩
    -ri=⟨Prepend to RAKULIB ./lib and these comma separated directories⟩

        At most one of these options may be specified. If none is
        specified, ./lib will be prepended to RAKULIB, the idea being
        that you will usually be running the program from the root of
        the module in development.

    -l :

        This will only alphabetically list all matching block labels.

    -q :

        Run blocks more quietly, preventing ｢ok:｣ and ｢# Subtest:｣
        lines from being displayed.

=head2 sub label ()

Used in a labeled block, returns the block's label. For example, when
run, the following block outputs «My label is a42␤»:

    t a42 => {
        say "My label is ", label;
    };

=head2 How do I skip running some blocks?

Prepend ｢__｣ or ｢_｣ (double or single underscore) to the block label:

    __  : The block will be completely ignored.

    _   : The block will not be run, but a 'skipped' message will be
          displayed.

Note that even if a block is completely ignored by ｢tsel｣, it must
nevertheless compile correctly; if it doesn't, you have no choice but
to fix, comment out, or remove the offending code.

Note also that skipped or ignored blocks will have their label, with
their underscore prefix, displayed by the -l option if the label
(without the underscores) matches the requested block glob.

=head2 Can I use different names for 't' and 'label'?

You may want to do that if for some reason ｢t｣ or ｢label｣ would cause
a name collision in your code (or maybe you just don't like those
names, eh). You can set the names you want instead at ｢use｣ time, by
passing the wanted names as arguments. To use a different name for
｢t｣, pass a single argument, the name you want. For example:

    use Test::Selector 'my-blocksub';

And you'd use it just like ｢t｣:

    my-blocksub ⟨some-label⟩ => { … };

To use a different name for ｢label｣, you need to pass two arguments:
the first one is the desired new (or same) name for ｢t｣, and the
second, the new name for ｢label｣. For example:

    use Test::Selector 't', 'my-labelsub';

Similarly, you'd use it just like ｢label｣:

    t a42 => {
        say "My label is ", my-labelsub;
    };

=head2 Full Example

Suppose you have the following (admittedly useless and dumb)
｢⋯/t/foo.rakutest｣ file:

    use Test;

    plan 3;

    my $str = 'abc';
    ok(
        $str.chars == $str.flip.chars,
        "A reversed string is the same length as the original.",
    );

    my $foo = 'xYz';
    ok(
        $foo !~~ / \d /,
        "The string '$foo' contains no digits.",
    );
    ok(
        $foo.chars == 3,
        "The string '$foo' has three characters.",
    );

    say "Hello, just printing this.";

Running ｢raku ⋯/t/foo.rakutest｣ would produce:

    1..3
    ok 1 - A reversed string is the same length as the original.
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hello, just printing this.
 
Now suppose you would like to sometimes run either one (or both) of
the string tests. Using this module, you could wrap those parts in
labeled blocks like shown below and have "done-testing" instead of a
"plan" (since not all tests will always be run). For example:

    use Test;
    use Test::Selector;

    t s1 => {
        my $str = 'abc';
        ok(
            $str.chars == $str.flip.chars,
            "A reversed string is the same length as the original.",
        );
    }

    t s2 => {
        my $foo = 'xYz';
        ok(
            $foo !~~ / \d /,
            "The string '$foo' contains no digits.",
        );
        ok(
            $foo.chars == 3,
            "The string '$foo' has three characters.",
        );
    }

    say "Hello, just printing this.";

    done-testing;

To run all the blocks, and thus all the tests, run it as before, or
invoke the supplied ｢tsel｣ program from the module's root directory
(which holds the ｢t/｣ subdirectory where our test file is), without
arguments:

    cd ⟨Module directory⟩
    tsel

That will print:

    # Testing foo.rakutest…
       # s1
    ok 1 - A reversed string is the same length as the original.
       # s2
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hello, just printing this.
    1..3

Notice a few differences:

    . The name of the file being tested is printed.
    . Output from a labeled block is preceded by the label
      printing that label.

Now let's ask ｢tsel｣ to run only the block labeled 's2':

    tsel s2

That prints:

    # Testing foo.rakutest…
       # s2
    ok 1 - The string 'xYz' contains no digits.
    ok 2 - The string 'xYz' has three characters.
    Hello, just printing this.
    1..2
 
Nice, but maybe we don't care about that "Hello" line or, for that
matter, any other code that may appear in the file. To prevent such
code from being run all the time, you could comment it out (it would
never run then, eh) or place all such code in one or more labeled
blocks. For example:

    t dont-care => {
        say "Hello, just printing this.";
    }

With that, running ｢tsel s1｣ would print:

    # Testing foo.rakutest…
       # s1
    ok 1 - A reversed string is the same length as the original.
    1..1
 
=head2 AUTHOR

Luc St-Louis <lucs@pobox.com>

=head2 COPYRIGHT AND LICENSE

Copyright © 2023 Luc St-Louis <lucs@pobox.com>

This library is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=end pod

# --------------------------------------------------------------------
use IO::Glob;

my $block-def_sub;
my $block-lbl_sub;

class Test::Selector {

    my $glob = %*ENV<TEST_SELECTOR_BLOCKS_GLOB> // '*';
    my $action = %*ENV<TEST_SELECTOR_ACTION> // 'run';

    proto sub block-lbl (|) is export {*}
    $block-lbl_sub = &block-lbl;

    multi sub block-lbl { return %*ENV<TEST_SELECTOR_LABEL> };

    proto sub block-def (|) is export {*}
    $block-def_sub = &block-def;

        # Allows arguments like ｢$a => { ⋯ }｣.
    multi sub block-def (Pair $def) {
        _block-def($def.key, $def.value);
    }

        # Allows arguments like ｢a => { ⋯ }｣. The previous sub
        # signature would fail, since a Pair within an argument list
        # with an unquoted identifier on the left is interpreted as a
        # named argument, not as a Pair.
    multi sub block-def (*%def) {
        my (Str $label, Block $code) = %def.kv;
        _block-def($label, $code);
    }

    sub _block-def (Str $label, Block $code) {
        my $to_match = $label;
        my $silent = so $to_match ~~ s/^__//;
        my $skip = so $to_match ~~ s/^_//;
        %*ENV<TEST_SELECTOR_LABEL> = $label;
        if ($to_match ~~ glob($glob)) {
            say($label), return if $action eq 'list';
            return unless $action eq 'run' && ! $silent;
            say("   # $label : skipped"), return if $skip;
            say "   # $label";
            $code.();
        }
    }

}

sub EXPORT ($block-def_sub-name = 't', $block-lbl_sub-name = 'label') {
    Map.new:
        "&$block-def_sub-name" => $block-def_sub,
        "&$block-lbl_sub-name" => $block-lbl_sub,
    ;
}

