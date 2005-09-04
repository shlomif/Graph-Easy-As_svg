#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 38;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

use Graph::Easy::Edge::Cell qw/EDGE_END_E EDGE_END_N EDGE_END_S EDGE_END_W EDGE_HOR/;

#############################################################################
my $graph = Graph::Easy->new();

is (ref($graph), 'Graph::Easy');

is ($graph->error(), '', 'no error yet');

is ($graph->nodes(), 0, '0 nodes');
is ($graph->edges(), 0, '0 edges');

is (join (',', $graph->edges()), '', '0 edges');

# this will load As_svg:
my $svg = $graph->as_svg();

# after loading As_svg, this should work:
can_ok ('Graph::Easy::Node', qw/as_svg/);
can_ok ('Graph::Easy', qw/as_svg_file/);

like ($svg, qr/enerated by/, 'contains generator notice');
like ($svg, qr/<svg/, 'looks like SVG');
like ($svg, qr/<\/svg/, 'looks like SVG');
like ($svg, qr/1\.1/, 'looks like SVG v1.1');
like ($svg, qr/\.node/, 'contains .node class');

#############################################################################
# with some nodes

my $bonn = Graph::Easy::Node->new( name => 'Bonn' );
my $berlin = Graph::Easy::Node->new( 'Berlin' );

$graph->add_edge ($bonn, $berlin);

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Berlin');
like ($svg, qr/<text/, 'contains <text');

like ($svg, qr/<rect/, 'contains <rect');
like ($svg, qr/<line/, 'contains <line (for edge)');

unlike ($svg, qr/<text.*?><\/text>/, "doesn't contain empty text tags");

#print $graph->as_svg(),"\n";

#############################################################################
# as_svg_file

$svg = $graph->as_svg_file();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/standalone="no"/, 'standalone');
like ($svg, qr/<\?xml/, 'contains <xml');

#print $graph->as_svg(),"\n";

#############################################################################

#############################################################################
# edge drawing (line_straigh)

sub LINE_HOR () { 0; }
sub LINE_VER () { 1; }

my $edge = Graph::Easy::Edge->new();
my $cell = Graph::Easy::Edge::Cell->new( edge => $edge, type => EDGE_HOR);
$cell->{w} = 100;
$cell->{h} = 50;

$svg = $cell->_svg_line_straight({}, 0, 0, LINE_HOR(), 0.1, 0.1, '' );
is ($svg, '<line x1="10" y1="25" x2="90" y2="25" />'."\n", 'line hor');

$svg = $cell->_svg_line_straight({}, 0, 0, LINE_VER(), 0.1, 0.1, '' );
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />'."\n", 'line ver');

$svg = $cell->_svg_line_straight({}, 0, 0, LINE_VER(), 0.1, 0.1, '' );
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />'."\n", 'line ver');

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_E,    0.1 , '' );
is ($svg, '<use xlink:href="#ah" x="90" y="25"/>'."\n", 'arrowhead east');

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_N,    0.1 , '' );
is ($svg, '<use xlink:href="#ah" transform="translate(50 5) rotate(-90)"/>'."\n", 'arrowhead north');

$svg = $cell->_svg_arrow({}, 0, 0, EDGE_END_S,    0.1 , '' );
is ($svg, '<use xlink:href="#ah" transform="translate(50 45) rotate(90)"/>'."\n", 'arrowhead south');

#############################################################################
# with some nodes with attributes

$graph = Graph::Easy->new();

$edge = $graph->add_edge ($bonn, $berlin);

$bonn->set_attribute( 'shape' => 'circle' );

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Bonn');
like ($svg, qr/circle/, 'contains circle shape');

#print $graph->as_svg(),"\n";

$bonn->set_attribute( 'shape' => 'rounded' );

$svg = $graph->as_svg();

like ($svg, qr/Bonn/, 'contains Bonn');
like ($svg, qr/Berlin/, 'contains Bonn');
like ($svg, qr/rect.*rx/, 'contains rect shape with rx/ry');
like ($svg, qr/line/, 'contains edge');
like ($svg, qr/text/, 'contains text');
like ($svg, qr/#ah/, 'contains arrowhead');

#print $graph->as_svg(),"\n";

$edge->set_attribute('style', 'double-dash');

$graph->layout();

$svg = $graph->as_svg();
like ($svg, qr/stroke-dasharray/, 'double dash contains dash array');


