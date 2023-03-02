=begin pod

=head1 NAME

Test::Selector - Have separately invokable labeled blocks in test files

=head1 SYNOPSIS

In your test files, ｢use｣ the Test::Selector module and wrap the
blocks you may want to separately invoke as follows, for example in
the ｢⟨Module directory⟩/t/04-foo.rakutest｣ file:

    use Test;
    use Test::Selector;

    t n1 => {
        my $n = 42;
        ok($n + $n == 2 * $n, "Adding a number to itself doubles it.");
        ok($n * $n == $n ^ 2, "Multiplying a number by itself squares it.");
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
            $s.uc.lc eq $s,lc,
            "Lowercasing an uppercased string is the same as just lowercasing it.",
        );
    };

Note that, all other things being equal, code that is not thusly
wrapped will run normally, so that if you use this module to wrap some
tests, it may be a good idea to wrap them all, or maybe wrap the ones
you don't necessarily want to run separately in a single big block, to
avoid running all that code all the time.

To run all the blocks in the example file, use plain Raku:

    cd ⟨Module directory⟩
    raku -Ilib t/04-foo.rakutest

or use the ｢tsel｣ program, supplied by this module, described later.

    cd ⟨Module directory⟩
    tsel -f=04

=head1 Rationale

During development of a module, you may want to run only one or more
of its tests to see how your code is coming along; you may not yet
care whether the other tests pass or not.

The traditional way to run tests separately is to have them in
different files, but this can lead to having many of them and it might
be hard to find which ones are relevant at any point during
development. It may be easier to find which tests to run if fewer
files have to be searched, thus this module.

When the module is ready for release, nothing special needs to be
done, and its tests will run (or not) normally when the module is
installed.

=head1 The ｢tsel｣ program

Supplied by this module, the program is used to select which labeled
blocks to run, in which test files, and where to look for modules.
Here are a few example invocations:

    cd ⟨Module directory⟩
    tsel -f=04 n1
    tsel -f=04 s\*
    tsel -q ⋯
    tsel -l s\*
    tsel -ri=⋯/SomeModule/lib,/⋯/OtherModule/lib ⋯

    cd ⟨Arbitrary directory⟩
    tsel -t=⋯/MyModule/t -r=⋯/MyModule/lib,/⋯/OtherModule/lib ⋯

｢tsel｣ has the following arguments:

    ⟨Blocks glob⟩ :

        Only blocks matching the specified glob will be used.
        Recognized glob characters and what they match are:

            *    : any string
            ?    : exactly one character
            […]  : characters from a set, for example ｢[abc]｣

        Default: ｢*｣

        Examples, with escaped ｢*｣, ｢?｣, and ｢[｣ characters, to
        prevent them being expanded by the shell, and labels they
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

            -f=04   Yes: 04-foo.t    No: 04-bar.raku

    -t=⟨Test files directories⟩ :

        Test files will be searched for in these comma separated
        directories.

        Default: ｢./t｣

    -r=⟨Directories to prepend to RAKULIB⟩

        Default: ｢./lib｣
        
    -ri=⟨Directories to prepend to RAKULIB, including ./lib⟩

        Default: ｢｣
        
          You may need to specify this if you are not running the
          program from within that directory (necessary to
          find the lib/ and t/ subdirectories).

    -l :

        This will only alphabetically list all matching block labels.
        
    -q :

        Run blocks more quietly, preventing ｢ok:｣ and ｢# Subtest:｣
        lines from being displayed.


=head1 sub label ()

Used in a block, returns the block's label. For example, when run, the
following block prints  «My label is a42␤»:

    t a42 => {
        say "My label is ", label;
    };

=head1 How do I skip running some blocks?

Prepend ｢__｣ or ｢_｣ to the block label:

    __  : The block will be completely ignored.

    _   : The block will not be run, but a 'skipped' message will be
          displayed.

=head1 Can I use different names for ｢t｣ and ｢label｣?

You may want to do that if for some reason ｢t｣ or ｢label｣ would cause
a name collision in your code (or maybe you just don't like those
names, eh). You can set the names you want instead at ｢use｣ time, by
passing the wanted names as arguments. To use a different name for
｢t｣, pass a single argument, the name you want. For example:

    use Test::Selector 'my-blocksub-name';

And you'd use it just like ｢t｣:

    my-blocksub-name ⟨some-label⟩ => { … };

To use a different name for ｢label｣, you need to pass two arguments:
the first one is the desired new (or same) name for ｢t｣, and the
second the new name for ｢label｣. For example:

    use Test::Selector 't', 'my-labelsub-name';

Similarly, you'd use it just like ｢label｣:

    t a42 => {
        say "My label is ", my-labelsub-name;
    };

=head1 AUTHOR

Luc St-Louis <lucs@pobox.com>

=head1 COPYRIGHT AND LICENSE

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

