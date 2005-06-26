#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 31;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   };

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

#print $graph->as_svg(),"\n";

#############################################################################
# edge drawing (line_straigh)

sub LINE_HOR () { 0; }
sub LINE_VER () { 1; }

my $edge = Graph::Easy::Edge::Cell->new();
$edge->{w} = 100;
$edge->{h} = 50;

$svg = $edge->_svg_line_straight('', 0, 0, LINE_HOR(), 0.1, 0.1, '' );
is ($svg, '<line x1="10" y1="25" x2="90" y2="25" />'."\n", 'line hor');

$svg = $edge->_svg_line_straight('', 0, 0, LINE_VER(), 0.1, 0.1, '' );
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />'."\n", 'line ver');

$svg = $edge->_svg_line_straight('', 0, 0, LINE_VER(), 0.1, 0.1, '' );
is ($svg, '<line x1="50" y1="5" x2="50" y2="45" />'."\n", 'line ver');

#				   EAST
$svg = $edge->_svg_arrow('', 0, 0, 1,    0.1 , '' );
is ($svg, '<use xlink:href="#ah" x="90" y="25"/>'."\n", 'arrowhead east');

#				   NORTH
$svg = $edge->_svg_arrow('', 0, 0, 3,    0.1 , '' );
is ($svg, '<use xlink:href="#ah" transform="translate(50 5) rotate(-90)"/>'."\n", 'arrowhead north');

#############################################################################
# with some nodes with atributes

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

