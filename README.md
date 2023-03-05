[![Actions Status](https://github.com/lucs/Test-Selector/actions/workflows/test.yml/badge.svg)](https://github.com/lucs/Test-Selector/actions)

NAME
====

Test::Selector - Selectively run only parts of test files

SYNOPSIS
--------

In your test file, wrap the parts you may want to run separately in blocks like shown here:

    use Test;
    use Test::Selector;

    t n1 => {
        my $n = 42;
        ok($n + $n == 2 * $n, "Adding a number to itself doubles it.");
        ok($n * $n == $n ** 2, "Multiplying a number by itself squares it.");
    };

    t s1 => {
        my $s = 'abc';
        ok(
            $s.chars == $s.flip.chars,
            "A string backwards has the same number of characters.",
        );
    };

    t s2 => {
        my $s = 'xYz';
        ok(
            $s.uc.lc eq $s.lc,
            "Lowercasing an uppercased string is the same as just lowercasing it.",
        );
    };

    done-testing;

To run all the blocks (and thus, all the tests), from the module's root directory, invoke the supplied ｢tsel｣ program without arguments:

    cd ⟨Module directory⟩
    tsel

To run only the blocks whose label matches the glob 's*', run it like this:

    tsel s\*

The '*' is escaped with a backslash to prevent the shell from expanding it to eventually matching file names.

Note that, all other things being equal, code that is not wrapped like above will run normally, so that if you use this module to wrap some tests, it may be a good idea to wrap them all, or maybe wrap the ones you don't necessarily want to run separately in a single big block, to avoid running all that code all the time.

Also note that this wrapping shouldn't interfere with ordinary testing, like just doing ｢raku ./t/mytests.rakutest｣ or when using ｢prove6｣ for example.

The ｢tsel｣ program
------------------

During development of a module, you may want to run only one or more of its tests to see how your code is coming along; you may not yet care whether the other tests pass or not, or may wish not to have to waste time while they are running.

The traditional way to run tests separately is to have them in different files, but this can lead to having many of them and it might be hard to find which ones are relevant at any point during development.

Supplied by this module, the ｢tsel｣ program is used to select some labeled blocks to run, and to specify where to look for and in which test files to look for the blocks, and where to look for other modules that may be necessary during development.

By default, ｢tsel｣ expects you to run it from the root directory of your module in development; that is, it expects to find there a ./t subdirectory with the test files, and a ./lib subdirectory to which it will set RAKULIB before running the tests.

Here are a few example invocations:

    cd ⟨Module directory⟩
    tsel -f=04 n1
    tsel -f=04 s\*
    tsel -q ⋯
    tsel -l s\*
    tsel -ri=⋯/SomeModule/lib,/⋯/OtherModule/lib ⋯

    cd ⟨Arbitrary directory⟩
    tsel -t=⋯/MyModule/t -r=⋯/MyModule/lib,⋯/OtherModule/lib ⋯

｢tsel｣ arguments
----------------

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

sub label ()
------------

Used in a labeled block, returns the block's label. For example, when run, the following block outputs «My label is a42␤»:

    t a42 => {
        say "My label is ", label;
    };

How do I skip running some blocks?
----------------------------------

Prepend ｢__｣ or ｢_｣ to the block label:

    __  : The block will be completely ignored.

    _   : The block will not be run, but a 'skipped' message will be
          displayed.

Can I use different names for ｢t｣ and ｢label｣?
----------------------------------------------

You may want to do that if for some reason ｢t｣ or ｢label｣ would cause a name collision in your code (or maybe you just don't like those names, eh). You can set the names you want instead at ｢use｣ time, by passing the wanted names as arguments. To use a different name for ｢t｣, pass a single argument, the name you want. For example:

    use Test::Selector 'my-blocksub-name';

And you'd use it just like ｢t｣:

    my-blocksub-name ⟨some-label⟩ => { … };

To use a different name for ｢label｣, you need to pass two arguments: the first one is the desired new (or same) name for ｢t｣, and the second the new name for ｢label｣. For example:

    use Test::Selector 't', 'my-labelsub-name';

Similarly, you'd use it just like ｢label｣:

    t a42 => {
        say "My label is ", my-labelsub-name;
    };

AUTHOR
------

Luc St-Louis <lucs@pobox.com>

COPYRIGHT AND LICENSE
---------------------

Copyright © 2023 Luc St-Louis <lucs@pobox.com>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

