[![Actions Status](https://github.com/lucs/Test-Selector.git/actions/workflows/test.yml/badge.svg)](https://github.com/lucs/Test-Selector.git/actions)

NAME
====

Test::Selector - Mark and selectively run only parts of test files

DESCRIPTION
-----------

During development of a module, you may want to run only one or more of the tests in its test files to see how your code is coming along; you may not yet care whether the other tests pass or not or you may just not want to have to wait for them to finish.

The traditional way to run tests separately is to have them in different files, but this can lead to having many of them and it might be hard to find which ones are relevant at any point during development.

With this module, you will be able to wrap into labeled blocks parts of your test files and use the supplied ｢tsel｣ program to select which of these blocks to run. It also lets you specify where to find the test files and in which ones to look for the blocks. You can also specify where to find other modules that may be required, but not yet installed.

Labeled blocks
--------------

Suppose you have the following (uninteresting) code in a test file:

    my $str = 'abc';
    ok(
        $str.chars == $str.flip.chars,
        "A reversed string is the same length as the original.",
    );

For the purpose of this module, you would wrap it like this with some arbitrary label, here 's1':

    t s1 => {
        my $str = 'abc';
        ok(
            $str.chars == $str.flip.chars,
            "A reversed string is the same length as the original.",
        );
    }

Then to run specifically that block, from the command line you would invoke ｢▸ tsel s1｣.

｢t｣ is a subroutine exported by the module. It can be invoked in one of the following example ways:

    t meep => { ⋯ }

    t $str => { ⋯ }

The latter form is useful when generating many similar tests; an example of this will be shown later.

The 'tsel' program
------------------

By default, ｢tsel｣ expects you to run it from the root directory of your module in development; that is, it expects to find there a ./t subdirectory with the test files, and a ./lib subdirectory to which it will set RAKULIB before running the tests.

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

    ⟨Blocks label pattern⟩ :

        Only blocks whose label matches the specified pattern will be
        run. Some characters in the pattern are special; here is what
        they match:

            *    : any string, zero or more characters
            ?    : exactly one character
            […]  : characters from a set, for example ｢[abc]｣

        Default: ｢*｣

        Here are some examples, escaping the special characters to
        prevent them from being expanded by the shell, and labels they
        could match or not:

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
        lines from being output.

    -qq :

        Run blocks even more quietly, preventing also any line whose first
        non-blank char is '#' from being output.

    -v :

        This will print the module version, something like
        "Test::Selector 0.2.0 on rakudo (2023.02)", and immediately
        exit the program.

sub label ()
------------

Used in a labeled block, returns the block's label. For example, when run, the following block prints «My label is a42␤»:

    t a42 => {
        say "My label is ", label;
    }

How do I skip running some blocks?
----------------------------------

Prepend ｢__｣ or ｢_｣ (double or single underscore) to the block label:

    __  : The block will be completely ignored.

    _   : The block will not be run, but a 'skipped' message will be
          output.

For example, given:

    t   s1 => { say "I'm block '{label}'." }
    t __s2 => { say "I'm block '{label}'." }
    t  _s3 => { say "I'm block '{label}'." }

running ｢▸ tsel s\*｣ will output something like this:

    # Testing ⟨the file⟩:
       # s1
    I'm block 's1'.
       # _s3 : skipped

Note that even if a block is completely ignored by ｢tsel｣, it must nevertheless compile correctly; if it doesn't, you have no choice but to fix, comment out, or remove the offending code.

Note also that skipped or ignored blocks will have their label, with their underscore prefix, displayed by the -l option if the label (without the underscores) matches the requested block label pattern. For example, given the same as above, running ｢▸ tsel -l s\*｣ will show something like this:

    # Labels in ⟨the file⟩:
    s1
    __s2
    _s3

Can I use different names for 't' and 'label'?
----------------------------------------------

You may want to do that if for some reason ｢t｣ or ｢label｣ would cause a name collision in your code (or maybe you just don't like those names, eh). You can set the names you want instead at ｢use｣ time, by passing the wanted names as arguments. To use a different name for ｢t｣, pass a single argument, the name you want. For example:

    use Test::Selector 'my-blocksub';

And you'd use it just like ｢t｣:

    my-blocksub ⟨some-label⟩ => { … }

To use a different name for ｢label｣, you need to pass two arguments: the first one is the desired new (or same) name for ｢t｣, and the second, the new name for ｢label｣. For example:

    use Test::Selector 't', 'my-labelsub';

Similarly, you'd use it just like ｢label｣:

    t a42 => {
        say "My label is ", my-labelsub;
    }

Full Example
------------

Suppose you have the following (admittedly useless and dumb) ｢⋯/t/foo.rakutest｣ file:

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

    say "Hi there!";

Running ｢▸ raku ⋯/t/foo.rakutest｣ would produce:

    1..3
    ok 1 - A reversed string is the same length as the original.
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hi there!

Now suppose you would like to sometimes run separately either the first test or the second and third together (they share the lexical-scoped $foo variable, so it makes sense, eh). Using this module, you could wrap those parts in labeled blocks and have "done-testing" instead of a "plan" (since not all tests will always be run). For example:

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

    say "Hi there!";

    done-testing;

To run all the blocks, and thus all the tests, run it as before, or invoke the supplied ｢tsel｣ program from the module's root directory (which holds the ｢t/｣ subdirectory where our test file is), without arguments:

    cd ⟨Module directory⟩
    tsel

That will print:

    # Testing foo.rakutest:
       # s1
    ok 1 - A reversed string is the same length as the original.
       # s2
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hi there!
    1..3

Notice a few differences:

    . The name of the file being tested is output.
    . Output from a labeled block is preceded by a comment
      displaying that label.

Now let's ask ｢tsel｣ to run only the block labeled 's2':

    tsel s2

That prints:

    # Testing foo.rakutest:
       # s2
    ok 1 - The string 'xYz' contains no digits.
    ok 2 - The string 'xYz' has three characters.
    Hi there!
    1..2

Nice, but maybe we don't care about that "Hi there!" line or, for that matter, any other code that may appear in the file. To prevent such code from being run all the time, you could comment it out (it would never run then, eh) or place all such code in one or more labeled blocks (prefixed or not with underscores to make them ignored, it's up to you). For example:

    t dont-care => {
        say "Hi there!";
    }

With that, running ｢▸ tsel s1｣ would output:

    # Testing foo.rakutest:
       # s1
    ok 1 - A reversed string is the same length as the original.
    1..1

One last example. Running ｢▸ tsel -q｣ would then output:

    # Testing foo.rakutest:
       # s1
       # s2
    1..3

Using a variable as a block label
---------------------------------

Suppose you're developing a function named foo(), and you have the following test blocks:

    t a1 => {
        is( (my $result = foo('x', 4)), 'xxxx' );
        is( $result.chars, 4 );
    }
    t a2 => {
        is( (my $result = foo('ZZZ', 2)), 'ZZZZZZ' );
        is( $result.chars, 6 );
    }
    t a3 => {
        is( (my $result = foo(5, 3)), 15 );
        is( $result.chars, 2 );
    }

Note that again, the example is contrived, useless, and dumb, and that the foo() function and its tests appear to be somewhat ill-conceived (but all that is another problem). What is interesting here is to note that all those blocks have the exact same structure, so we could do this instead (full code included, even that foo() function):

    use Test;
    use Test::Selector;

    sub foo ($c, Int $i) {
        return $c ~~ Int ?? $c * $i !! $c x $i;
    }

    sub check-foo (
        $block-id,
        $arg1,
        $arg2,
        $expected-result,
        $expected-length,
    ) {
        t "a$block-id" => {
            is( (my $result = foo($arg1, $arg2)), $expected-result );
            is( $result.chars, $expected-length );
        }
    }

    check-foo |< 1 x   4 xxxx   4 >;
    check-foo |< 2 ZZZ 2 ZZZZZZ 6 >;
    check-foo |< 3 5   3 15     2 >;

    done-testing;

So to run only the last one, you'd invoke ｢▸ tsel a3｣.

Now the test data is much easier to prepare and if the structure of the test itself needs to be modified, it's going to be easy too.

Note that a similar technique can, and probably should, be used when preparing tests that don't use this module.

AUTHOR
------

Luc St-Louis <lucs@pobox.com>

COPYRIGHT AND LICENSE
---------------------

Copyright © 2023 Luc St-Louis <lucs@pobox.com>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

