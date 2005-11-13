#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 5;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_svg") or die($@);
   };

#############################################################################

my $l = 'Graph::Easy::As_svg::_text_length';

no strict 'refs';

is ($l->(14, 'ABCDE'), 3.5, 'ABCDE is 3.5 long');
is ($l->(14, 'WW'), 0.9*2, 'WW');
is ($l->(14, 'ii'), 0.33*2, 'ii');
