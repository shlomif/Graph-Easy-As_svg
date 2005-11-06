#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 56;
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

like ($svg, qr/enerated at .* by/, 'contains generator notice');
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
like ($svg, qr/standalone="yes"/, 'standalone');
like ($svg, qr/xmlns="/, 'xmlns');
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

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_HOR(), 0.1, 0.1 ));
is ($svg, '<line x1="10" y1="25" x2="90" y2="25" />', 'line hor');

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_VER(), 0.1, 0.1 ));
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />', 'line ver');

$svg = join ('', $cell->_svg_line_straight(0, 0, LINE_VER(), 0.1, 0.1 ));
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />', 'line ver');

#############################################################################
# arrorw drawing

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
like ($svg, qr/rx="15" ry="15"/, 'contains rect shape with rx/ry');
like ($svg, qr/line/, 'contains edge');
like ($svg, qr/text/, 'contains text');
like ($svg, qr/#ah/, 'contains arrowhead');

#print $graph->as_svg(),"\n";

$edge->set_attribute('style', 'double-dash');

$graph->layout();

$svg = $graph->as_svg();
like ($svg, qr/stroke-dasharray/, 'double dash contains dash array');

#############################################################################
# unused definitions are not in the output
 
unlike ($svg, qr/(diamond|circle|triangle)/, 'unused defs are not there');

#############################################################################
# color on edge labels

$edge->set_attribute('color', 'orange');

$svg = $graph->as_svg();
like ($svg, qr/stroke="#ffa500"/, 'orange stroke on edge');
unlike ($svg, qr/color="#ffa500"/, 'no orange color on edge');
unlike ($svg, qr/fill="#ffa500"/, 'no orange fill on edge');

$edge->set_attribute('label', 'Schmabel');

is ($edge->label(), 'Schmabel', 'edge label');

$svg = $graph->as_svg();
like ($svg, qr/stroke="#ffa500"/, 'orange stroke on edge');
like ($svg, qr/fill="#ffa500"/, 'orange color on edge label');
unlike ($svg, qr/color="#ffa500"/, 'no orange color on edge');

#############################################################################
# text-style support

$edge->set_attribute('text-style', 'bold underline');

$svg = $graph->as_svg();
like ($svg, qr/font-weight="bold" text-decoration="underline"/, 'text-style');

$edge->set_attribute('text-style', 'bold underline overline');

$svg = $graph->as_svg();
like ($svg, qr/font-weight="bold" text-decoration="underline overline"/, 'text-style');

#############################################################################
# font-size support

$edge->set_attribute('font-size', '2em');

$svg = $graph->as_svg();
like ($svg, qr/style="font-size:28px"/, '2em == 28 px');

#############################################################################
# <title>

$svg = $graph->as_svg();
like ($svg, qr/<title>Untitled graph<\/title>/, 'no title by default');

$graph->set_attribute('graph','label', 'My Graph');
$svg = $graph->as_svg();
like ($svg, qr/<title>My Graph<\/title>/, 'set title');

$graph->set_attribute('graph','title', 'My Graph Title');
$svg = $graph->as_svg();
like ($svg, qr/<title>My Graph Title<\/title>/, 'title overrides label');


#############################################################################
# support for rotate

$bonn->set_attribute( 'rotate' => 'right' );

is ($bonn->attribute('rotate'), '90', 'rotate right is +90 degrees');

$svg = $graph->as_svg();
like ($svg, qr/rect.*transform="rotate\(90,/, 'rotate right = 90');

