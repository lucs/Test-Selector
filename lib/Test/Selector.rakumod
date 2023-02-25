=begin pod

=head1 NAME

Test::Selector - Have separately invokable labeled blocks in test files

=head1 SYNOPSIS

In your test files, ｢use｣ the Test::Selector module and wrap the
blocks you may want to separately invoke as follows, for example in
the ｢⟨Module directory⟩/t/04-foo.rakumod｣ file:

    use Test;
    use Test::Selector;

    t n1 => {
        my $n = 42;
        ok($n + $n == 2 * $n, "Adding a number to itself doubles it.");
    };

    t n2 => {
        my $n = 23;
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
wrapped will run normally.

To run all the blocks in the example file, use plain Raku:

    cd ⟨Module directory⟩
    raku -Ilib t/04-foo.rakumod

or use the ｢test_select.raku｣ program, supplied by this module:

        Run labeled blocks only in files found under the ｢t/｣
        subdirectory of the ⟨Module directory⟩ and whose name begins
        as shown by the ｢-f｣ option.
    test_select.raku ⟨Module directory⟩ -f=04

To run only the block labeled ｢n2｣ in that file:

    test_select.raku ⟨Module directory⟩ -f=04 -t=n2

Similarly, to run all the blocks whose label begins with ｢s｣ (the ｢*｣
is escaped with a ｢\｣ to prevent shell expansion):

    test_select.raku ⟨Module directory⟩ -f=04 -t=s\*

To run tests quietly, preventing ｢ok:｣ and ｢# Subtest:｣ lines from
being displayed:

    test_select.raku ⟨Module directory⟩ -f=04 -q

To simply list all the block labels found in the file:

    test_select.raku ⟨Module directory⟩ -f=04 -l

Note that if the ｢-f｣ option is absent, all test files found under the
｢⟨Module directory⟩/t｣ directory will be used.

=head1 Rationale

During development of a module, you may want to run only one or more
of its tests to see how your code is coming along; you may not
care whether the other tests pass or not.

The traditional way to run tests separately is to have them in
different files, but this can lead to having many of them and it might
be hard to find which ones are relevant at any point during
development. It may be easier to find which tests to run if fewer
files have to be searched, thus this module.

When the module is ready for release, nothing special needs to be
done, and its tests will run (or not) normally when the module is
installed.

=head1 The ｢test_select.raku｣ program

Supplied by this module, the program is used to select which labeled
blocks to run and in which test files.

It has one mandatory argument: the directory holding the module's
development code, where its ｢./lib｣ directory will be prepended to the
RAKULIB envvar when running the blocks, and its ｢./t｣ directory, which
will be searched for the files holding the labeled blocks.

It has the following optional arguments:

    -f=⟨Prefix of test files to use⟩ :

        Only files whose name starts with the prefix characters, will
        be used, and whose extension is ｢.t｣ or ｢.rakutest｣, will be
        used.

        Default: all files with the proper extension will be used.
        Example:

            -f=04   Yes: 04-foo.t    No: 04-bar.raku

    -t=⟨Glob of block labels to use⟩ :

        Only blocks matching this glob will be used.

            *    : any string
            ?    : exactly one character
            […]  : characters from a set, for example ｢[abc]｣

        Default: ｢*｣

        Examples, with escaped ｢*｣, ｢?｣, and ｢[｣ characters, to prevent
        them being expanded by the shell, and labels they could match:

            -t=n\*      Yes: n, n1, nything     No: anything
            -t=\[ab]\*c Yes: axc, a23c, bc      No: abcd, edc
            -t=a1\?     Yes: a11, a1rx          No: a1

    -l :

        Will run no blocks, just alphabetically list all matching
        block labels
        
    -q :

        Run blocks more quietly, preventing ｢ok:｣ and ｢# Subtest:｣
        lines from being displayed.

=head1 sub label ()

Used in a block, returns the subroutine's label. For example, the
following prints  «My label is a42␤»:

    t a42 => {
        say "My label is ", label;
    }

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

    use Test::Selector 'my-tsub-name';

And you'd use it just like ｢t｣:

    my-tsub-name some-label => { … };

To use a different name for ｢label｣, you need to pass two arguments:
the first one is the desired new (or same) name for ｢t｣, and the
second the new name for ｢label｣. For example:

    use Test::Selector 't', 'my-labelsub-name'

Similarly, you'd use it just like ｢label｣:

    t a42 => {
        say "My label is ", my-labelsub-name;
    }

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

    my $glob = %*ENV<TEST_SELECTOR_LABELS_GLOB> // '*';
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

