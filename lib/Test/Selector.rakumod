=begin pod

=head1 NAME

Test::Selector - Mark and selectively run only parts of test files

=head2 DESCRIPTION

During development of a module, you may want to run only one or more
of the tests in its test files to see how your code is coming along;
you may not yet care whether the other tests pass or not or you may
just not want to have to wait for them to finish or to clutter up the
screen.

The traditional way to run tests separately is to have them in
different files, but this can lead to having many of them and it might
be hard to find which ones are relevant at any point during
development.

With this module, you will be able to wrap into labeled blocks parts
of your test files and use the supplied C<tsel> program to select which
of these blocks to run. It also lets you specify where to find the
test files and in which ones to look for the blocks. You can also
specify where to find other modules that may be required, but not yet
installed.

=head2 Labeled blocks

Suppose you have the following (uninteresting) code in a test file:

=begin code
    my $str = 'abc';
    ok(
        $str.chars == $str.flip.chars,
        "A reversed string is the same length as the original.",
    );
=end code

For the purpose of this module, you would wrap it like this with some
arbitrary label, here 's1':

=begin code
    t s1 => {
        my $str = 'abc';
        ok(
            $str.chars == $str.flip.chars,
            "A reversed string is the same length as the original.",
        );
    }
=end code

Then to run specifically that block, from the command line you would
invoke C<▸ tsel s1>.

C<t> is a subroutine exported by the module. It can be invoked in one
of the following example ways:

=begin code
    t some-label => { ⋯ }

    t $some-var => { ⋯ }
=end code

The latter form is useful when generating many similar tests; an
example of this will be shown later.

=head2 The C<tsel> program

By default, C<tsel> expects you to run it from the root directory of
your module in development; that is, it expects to find there a C<./t>
subdirectory with the test files, and a C<./lib> subdirectory to which
it will set RAKULIB before running the tests.

Here are a few example invocations:

=begin code
    cd ⟨Module directory⟩
    tsel s1
    tsel -f=04 s\*
    tsel -q ⋯
    tsel -l s\*
    tsel -ri=⋯/SomeModule/lib,/⋯/OtherModule/lib ⋯

    cd ⟨Arbitrary directory⟩
    tsel -t=⋯/MyModule/t -r=⋯/MyModule/lib,⋯/OtherModule/lib ⋯
=end code

C<tsel> has the following arguments:

=begin code
    ⟨Blocks label pattern⟩ :

        Only blocks whose label matches the specified pattern will be
        run. Some characters in the pattern are special; here is what
        they match:

            *    : any string, zero or more characters
            ?    : exactly one character
            […]  : characters from a set, for example ‹[abc]›

        Default: ‹*›

        Here are some examples, escaping the special characters to
        prevent them from being expanded by the shell, and labels they
        could match or not:

            n\*      Yes: n, n1, nything     No: an
            \[ab]\*c Yes: axc, a23c, bc      No: bcd, ebc
            a1\?     Yes: a11, a1x           No: a1, a1bc

    -f=⟨Files prefix⟩ :

        Only files whose extension is ‹.rakutest›, ‹.t›, or ‹.t6› and
        whose name starts with the specified prefix characters will be
        used.

        Default: all files with the proper extension will be used.

        Example:

            -f=04   Yes: 04-baz.rakutest, 04.t6  No: 04-foo.raku

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

        Run blocks more quietly, preventing ‹ok:› and ‹# Subtest:›
        lines from being output.

    -qq :

        Run blocks even more quietly, preventing also any line whose first
        non-blank char is ‹#› from being output.

    -v :

        This will print the module version, something like
        "Test::Selector 0.2.0 on rakudo (2023.02)", and immediately
        exit the program.
=end code

=head2 sub C<label()>

Used in a labeled block, returns the block's label. For example:

=begin code
        # If this block runs, it will print «My label is a42␤».
    t a42 => {
        say "My label is ", label;
    }
=end code

=head2 How do I skip running some blocks?

Prepend one or two underscores to the block label:

=begin code
    _   : The block will not be run, even if it matches the label
          glob, but a 'skipped' message will be output.

    __  : The block will be completely ignored.
=end code

For example, given:

=begin code
    t   s1 => { say "I'm block '{label}'." }
    t __s2 => { say "I'm block '{label}'." }
    t  _s3 => { say "I'm block '{label}'." }
=end code

running C<▸ tsel s\*> will output something like this:

=begin code
    # Testing ⟨the file⟩:
       # s1
    I'm block 's1'.
       # _s3 : skipped
=end code

Note that even if a block is completely ignored by C<tsel>, it must
nevertheless compile correctly; if it doesn't, you have no choice but
to fix, comment out, or remove the offending code.

Note also that skipped or ignored blocks will have their label, with
their underscore prefix, displayed by the C<-l> option if the label
without the underscores matches the requested block label pattern.
For example, given the same as above, running C<▸ tsel -l s\*> will
show something like this:

=begin code
    # Labels in ⟨the file⟩:
    s1
    __s2
    _s3
=end code

=head2 Can I use different names for C<t> and C<label>?

You may want to do that if for some reason C<t> or C<label> would cause
a name collision in your code (or maybe you just don't like those
names, eh). You can set the names you want instead at C<use> time, by
passing the wanted names as arguments. To use a different name for
C<t>, pass a single argument, the name you want. For example:

=begin code
    use Test::Selector 'my-blocksub';
=end code

And you'd use it just like C<t>:

=begin code
    my-blocksub ⟨some-label⟩ => { … }
=end code

To use a different name for C<label>, you need to pass two arguments:
the first one is the desired new (or same) name for C<t>, and the
second, the new name for C<label>. For example:

=begin code
    use Test::Selector 't', 'my-labelsub';
=end code

Similarly, you'd use it just like C<label>:

=begin code
    t a42 => {
        say "My label is ", my-labelsub;
    }
=end code

=head2 Full Example

Suppose you have the following (again, uninteresting) code in the
C<./t/baz.rakutest> file:

=begin code
    use Test;

    plan 3;

    my $str = 'abc';
    ok(
        $str.chars == $str.flip.chars,
        "A reversed string is the same length as the original.",
    );

    my $baz = 'xYz';
    ok(
        $baz !~~ / \d /,
        "The string '$baz' contains no digits.",
    );
    ok(
        $baz.chars == 3,
        "The string '$baz' has three characters.",
    );

    say "Hi there!";
=end code

Running C<▸ raku ⋯/t/baz.rakutest> would produce:

=begin code
    1..3
    ok 1 - A reversed string is the same length as the original.
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hi there!
=end code

Now suppose you would like to sometimes run separately either the
first test or the second and third together -- the latter share the
C<$baz> variable, so it makes sense. You could wrap those parts in
labeled blocks and have C<done-testing> instead of C<plan 3>, since
not all tests will always be run. For example:

=begin code
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
        my $baz = 'xYz';
        ok(
            $baz !~~ / \d /,
            "The string '$baz' contains no digits.",
        );
        ok(
            $baz.chars == 3,
            "The string '$baz' has three characters.",
        );
    }

    say "Hi there!";

    done-testing;
=end code

To run all the blocks, and thus all the tests, run it as before, or
invoke C<tsel> without arguments from the module's root directory. In
what follows, we will suppose that that the C<baz.rakutest> file is
the only file under C<./t>:

=begin code
    cd ⟨Module directory⟩
    tsel
=end code

That will print:

=begin code
    # Testing baz.rakutest:
       # s1
    ok 1 - A reversed string is the same length as the original.
       # s2
    ok 2 - The string 'xYz' contains no digits.
    ok 3 - The string 'xYz' has three characters.
    Hi there!
    1..3
=end code

Notice a few things:

=begin code
    . The name of the file being tested is output.
    . Output from a labeled block is preceded by a comment
      displaying that label.
=end code

Now let's ask C<tsel> to run only the block labeled 's2':

=begin code
    tsel s2
=end code

That prints:

=begin code
    # Testing baz.rakutest:
       # s2
    ok 1 - The string 'xYz' contains no digits.
    ok 2 - The string 'xYz' has three characters.
    Hi there!
    1..2
=end code

Nice, but maybe we don't care about that "Hi there!" line or, for that
matter, any other code that may appear in the file. To prevent such
code from being run all the time, you could comment it out (it would
never run at all then, eh) or place all such code in one or more labeled
blocks, prefixed or not with underscores to make them ignored, it's up
to you. For example:

=begin code
    t dont-care => {
        say "Hi there!";
    }
=end code

With that, running C<▸ tsel s1> would output:

=begin code
    # Testing baz.rakutest:
       # s1
    ok 1 - A reversed string is the same length as the original.
    1..1
=end code

Two last examples. Running C<▸ tsel -q> would then output:

=begin code
    # Testing baz.rakutest:
       # s1
       # s2
    1..3
=end code

And C<▸ tsel -qq>:

=begin code
    1..3
=end code

=head2 Using a variable as a block label

Suppose you're developing a function named C<jub()>:

=begin code
    sub jub ($c, Int $i) {
        return $c ~~ Int ?? $c * $i !! $c x $i;
    }
=end code

You could have the following test blocks:

=begin code
    t a1 => {
        is( (my $result = jub('x', 4)), 'xxxx' );
        is( $result.chars, 4 );
    }
    t a2 => {
        is( (my $result = jub('ZZZ', 2)), 'ZZZZZZ' );
        is( $result.chars, 6 );
    }
    t a3 => {
        is( (my $result = jub(5, 3)), 15 );
        is( $result.chars, 2 );
    }
=end code

The (only) interesting thing here is that all the test blocks have the
exact same structure, so we could refactor to this:

=begin code
    use Test;
    use Test::Selector;

    sub jub ($c, Int $i) {
        return $c ~~ Int ?? $c * $i !! $c x $i;
    }

    sub check-jub (
        $block-id,
        $arg1,
        $arg2,
        $expected-result,
        $expected-length,
    ) {
        t "a$block-id" => {
            is( (my $result = jub($arg1, $arg2)), $expected-result );
            is( $result.chars, $expected-length );
        }
    }

    check-jub |< 1 x   4 xxxx   4 >;
    check-jub |< 2 ZZZ 2 ZZZZZZ 6 >;
    check-jub |< 3 5   3 15     2 >;

    done-testing;
=end code

So to run only the last one, you'd invoke C<▸ tsel a3>.

Now the test data is much easier to prepare and if the structure of
the test itself needs to be modified, it's going to be easy too.

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

class Test::Selector:ver<0.3.3>:auth<zef:lucs> {

    my $glob = %*ENV<TEST_SELECTOR_WANT> // '*';
    my $action = %*ENV<TEST_SELECTOR_ACTION> // 'run';

    proto sub block-lbl (|) is export {*}
    $block-lbl_sub = &block-lbl;

    multi sub block-lbl { return %*ENV<TEST_SELECTOR_LABEL> }

    proto sub block-def (|) is export {*}
    $block-def_sub = &block-def;

        # Allows arguments like ‹$a => { ⋯ }›.
    multi sub block-def (Pair $def) {
        _block-def($def.key, $def.value);
    }

        # Allows arguments like ‹a => { ⋯ }›. The previous sub
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

                # Appears to avoid bad sequencing of outputs to OUT
                # and ERR when $code invokes methods from the Test
                # module.
            my Str $capture = '';
            with class :: {
                method print($s) { $capture ~= $s }
            }.new xx 2 -> ($*OUT, $*ERR) { $code.(); };
            print $capture;
        }
    }

}

sub EXPORT ($block-def_sub-name = 't', $block-lbl_sub-name = 'label') {
    Map.new:
        "&$block-def_sub-name" => $block-def_sub,
        "&$block-lbl_sub-name" => $block-lbl_sub,
    ;
}

