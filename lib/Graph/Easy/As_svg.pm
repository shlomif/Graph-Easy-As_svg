#############################################################################
# output the a Graph::Easy as SVG (Scalable Vector Graphics)
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Easy::As_svg;

use vars qw/$VERSION/;

$VERSION = '0.06';

use Graph::Easy;

#############################################################################
#############################################################################

package Graph::Easy;

sub EM () { 14; }

use strict;

sub _as_svg
  {
  # convert the graph to SVG
  my ($self, $options) = @_;

  $self->layout() unless defined $self->{score};

  my ($rows,$cols,$max_x,$max_y,$cells) = $self->_prepare_layout('svg');

  my $txt;

  if ($options->{standalone})
    {
    $txt .= <<EOSVG
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

EOSVG
;
    }

  # XXX TODO: that should use the padding/margin attribute from the graph
  my $xl = int(EM * 1); my $yl = int(EM * 1);
  my $xr = int(EM * 1); my $yr = int(EM * 1);

  my $mx = $max_x + $xl + $xr;
  my $my = $max_y + $yl + $yr;

  $txt .=
     "<svg viewBox=\"0 0 $mx $my\" version=\"1.1\">"
    ."\n<!-- Generated by Graph::Easy v$Graph::Easy::VERSION" .
	    " at " . scalar localtime() . " -->\n\n";

  # XXX TODO: diamond
#  $txt .= "<defs>\n <g id=\"diamond\">\n  <rect x=\"-0.5\" y=\"-0.5\" width=\"1\" height=\"1\"/>\n </g> </defs>\n\n";

  $txt .= " <defs>\n";

  $txt .= "  <!-- arrow head -->\n  <g id=\"ah\">\n";
  $txt .= '   <line x1="-8" y1="-4" x2="1" y2="0" stroke-linecap="round" />'. "\n";
  $txt .= '   <line x1="1" y1="0" x2="-8" y2="4" stroke-linecap="round" />'. "\n";
  $txt .= "  </g>\n";
 
  # which attributes must be output as what name:
  my $mutator = {
    background => 'fill',
#    'border-color' => 'stroke',
    'text-align' => 'text-anchor',
    'color' => 'stroke',
    };
  my $skip = qr/^(
   label|
   linkbase|
   (auto)?(link|title)|
   nodeclass|
   border-style|
   padding.*|
   margin.*|
   line-height|
   letter-spacing|
   font-family|
   border|
   width|
   color|
   text-align|
   border-color|
   shape
   )\z/x;

  my $overlay = {
    node => {
      "text-anchor" => 'middle',
    },
  };
  # generate the class attributes first
  my $style = $self->_class_styles( $skip, $mutator, '', '  ', $overlay);

  ## output groups first, with their nodes
  #foreach my $gn (sort keys %{$self->{groups}})
  #  {
  #  my $group = $self->{groups}->{$gn};
  #  $txt .= $group->as_txt();		# marks nodes as processed if nec.
  #  $count++;
  #  }

  $txt .= 
    "\n  <!-- class definitions -->\n"
   ."  <style type=\"text/css\"><![CDATA[\n$style  "
   # include a pseudo-class ".text" to shorten output
   .".text {\n   text-anchor: middle;\n   font-size: 14;\n  }\n"
   ."  ]]></style>\n"
    if $style ne '';
 
  $txt .=" </defs>\n\n";

  # now output all the occupied cells
  foreach my $n (@$cells)
    {
    # exclude filler cells
    if ($n->{minw} != 0 && $n->{minh} != 0)
      {
      # get position from cell
      my $x = $cols->{ $n->{x} } + $xl;
      my $y = $rows->{ $n->{y} } + $yl;

      my $class = $n->{class}; $class =~ s/\./-/;	# node.city => node-city
      my $indent = '  ';
      $txt .= "<g class=\"$class\">\n";
      $txt .= $n->as_svg($x,$y,'  ');	# output cell, indented
      $txt =~ s/\n\z/<\/g>\n\n/;
      }
    }

  $txt . "</svg>";			# finish
  }

=pod

=head1 NAME

Graph::Easy::As_svg - Output a Graph::Easy as Scalable Vector Graphics (SVG)

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_svg();

	# prints something like:


=head1 DESCRIPTION

C<Graph::Easy::As_svg> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a SVG text.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

package Graph::Easy::Node;

sub as_svg
  {
  my ($self,$x,$y,$indent) = @_;

  my $name = $self->{att}->{label}; $name = $self->{name} unless defined $name;

  my $em = Graph::Easy::EM;		# multiplication factor chars * em = units (pixels)

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes($x,$y);
  
  my $shape = $att->{shape};				# rect, circle etc
  delete $att->{shape};

  # set a potential title
  my $title = $self->title();
  $att->{title} = $title if $title ne '';

  my $att_txt = $self->_svg_attributes_as_txt($att);

  my $svg = "$indent<!-- $name -->\n";
  
  $svg .= "$indent<$shape$att_txt />\n" unless $shape eq 'invisible'; 

  ###########################################################################
  # include the label/name/text
 
  my $label = $self->label();

  my $xt = int($x + $em * 0.05 + $self->{w} / 2);
  my $yt = int($y + $self->{h} / 2 + $em / 2 - $em * 0.1);
  my $color = $self->attribute('color') || 'black';

  $svg .= "$indent<text class=\"text\" x=\"$xt\" y=\"$yt\" fill=\"$color\">$label</text>\n\n";

  $svg;
  }

my $strokes = {
  'dashed' => '4, 2',
  'dotted' => '2, 2',
  'dot-dash' => '2, 2, 4, 2',
  'dot-dot-dash' => '2, 2, 2, 2, 4, 2',
  };

sub _svg_attributes
  {
  # Return a hash with attributes for the node, like "x => 1, y => 1, w => 1, h => 1"
  # Especially usefull for shapes other than boxes.
  my ($self,$x,$y) = @_;

  my $att = {};

  my $shape = $self->shape();

  my $w2 = $self->{w} / 2;
  my $h2 = $self->{h} / 2;
  if ($shape eq 'circle')
    {
    $att->{cx} = $x + $w2;
    $att->{cy} = $y + $h2;
    $att->{r} = $self->{minw} > $self->{minh} ? $self->{minw} : $self->{minh};
    $att->{r} /= 2;
    }
  elsif ($shape eq 'diamond')
    {
    # XXX TODO: diamond
    my $d = $self->{minw} > $self->{minh} ? $self->{minw} : $self->{minh};
    $att->{width} = $d;
    $att->{height} = $d;
    $att->{x} = $x + $w2 - $d / 2;
    $att->{y} = $y + $h2 - $d / 2;
    $shape = 'rect';
    }
  elsif ($shape eq 'ellipse')
    {
    $att->{cx} = $x + $w2;
    $att->{cy} = $y + $h2;
    $att->{rx} = $w2;
    $att->{ry} = $h2;
    }
  else
    {
    if ($shape eq 'rounded')
      {
      # round corners by 10%
      $att->{ry} = '10%';
      $att->{rx} = '10%';
      $shape = 'rect';
      }
    $att->{x} = $x;
    $att->{y} = $y;
    $att->{width} = $self->{w};
    $att->{height} = $self->{h};

    # XXX TODO: other shapes than rectangles like polygon etc
    }
  $att->{shape} = $shape;

  my $border_style = $self->attribute('border-style') || 'solid';
  my $border_color = $self->attribute('border-color') || 'black';
  my $border_width = $self->attribute('border-width') || '1';

  $att->{'stroke-width'} = $border_width if $border_width ne '1';
  $att->{stroke} = $border_color;

  if ($border_style !~ /^(none|solid)/)
    {
    $att->{'stroke-dasharray'} = $strokes->{$border_style}
     if exists $strokes->{$border_style};
    }

  $att->{'stroke-width'} = 3 if $border_style eq 'bold';
  if ($border_style eq 'none')
    {
    delete $att->{'stroke-width'};
    delete $att->{stroke};
    }
  my $background = $self->attribute('background') || '';
  $att->{fill} = $background if $background ne '';

  $att;
  }

sub _svg_attributes_as_txt
  {
  # convert hash with attributes to text to be included in SVG tag
  my ($self, $att) = @_;

  my $att_line = '';				# attributes as text (cur line)
  my $att_txt = '';				# attributes as text (all)
  foreach my $e (sort keys %$att)
    {
    $att_line .= " $e=\"$att->{$e}\"";
    if (length($att_line) > 75)
      {
      $att_txt .= "$att_line\n  "; $att_line = '';
      }
    }
  $att_txt .= "$att_line";
  $att_txt =~ s/\n\z//;		# avoid a "  >" on last line
  $att_txt;
  }
 
sub _correct_size_svg
  {
  # Correct {w} and {h} after parsing.
  my $self = shift;

  my $em = Graph::Easy::EM;		# multiplication factor chars * em = units (pixels)

  return if defined $self->{w};

  my $txt = $self->label();

  my ($w,$h) = $self->dimensions();
  # XXX TODO: that should use a changable padding factor (like "0.2 em" or "4")
  $self->{w} = int($w * $em + 0.2 * $em);
  $self->{h} = int($h * $em + 0.8 * $em);
  my $border = $self->attribute('border-style') || 'none';
  if ($border ne 'none')
    {
    # XXX TODO: that should use the border width (like "1 pixel" * 2)
    $self->{w} += 2;
    $self->{h} += 2;
    }
  my $shape = $self->shape();

  if ($shape =~ /^(diamond|circle)$/)
    {
    # the min size is either w or h, depending on which is bigger
    my $max = $self->{w}; $max = $self->{h} if $self->{h} > $max;
    $self->{h} = $max;
    $self->{w} = $max;
    }
  }
 
1;

# XXX TODO:
# use <line ...> for Graph::Easy::Edge

package Graph::Easy::Edge::Cell;

#############################################################################
#############################################################################
# Line drawing code for edges

# define the line lengths for the different edge types

sub LINE_HOR () { 0x0; }
sub LINE_VER () { 0x1; }

sub LINE_MASK () { 0x0F; }
sub LINE_DOUBLE () { 0x10; }

# arrow types
sub NONE () { 0; }
sub EAST () { 1; }
sub WEST () { 2; }
sub NORTH () { 3; }
sub SOUTH () { 4; }

  # edge type       line type  spacing left/top
  #				    spacing right/bottom

my $draw_lines = {
  EDGE_SHORT_E()	=> [ EAST,  LINE_HOR,  0.1, 0.1 ],	# |->	a start/end at the same cell
  EDGE_SHORT_N()	=> [ NORTH, LINE_VER,  0.1, 0.1 ],	# v	a start/end at the same cell
  EDGE_SHORT_W()	=> [ WEST,  LINE_HOR,  0.1, 0.1 ],	# <-|	a start/end at the same cell
  EDGE_SHORT_S()	=> [ SOUTH, LINE_VER,  0.1, 0.1 ],	# ^	a start/end at the same cell

  EDGE_START_E()	=> [ NONE,  LINE_HOR,  0.1, 0   ],	# |--	starting-point
  EDGE_START_N()	=> [ NONE,  LINE_VER,  0,   0.1 ],	# |	starting-point
  EDGE_START_W()	=> [ NONE,  LINE_HOR,  0,   0.1 ],	# --|	starting-point
  EDGE_START_S()	=> [ NONE,  LINE_VER,  0.1, 0   ],	# |	starting-point

  EDGE_END_E()		=> [ EAST,  LINE_HOR,  0,   0.1 ],	# -->	end-point
  EDGE_END_N()		=> [ NORTH, LINE_VER,  0.1, 0   ],	# ^	end-point
  EDGE_END_W()		=> [ WEST,  LINE_HOR,  0.1, 0   ],	# <--	end-point
  EDGE_END_S()		=> [ SOUTH, LINE_VER,  0,   0.1 ],	# v	end-point

  EDGE_VER()		=> [ NONE,  LINE_VER,  0,   0  ],	# |	vertical line
  EDGE_HOR()		=> [ NONE,  LINE_HOR,  0,   0  ],	# --	vertical line

  EDGE_CROSS()		=> [ NONE,  LINE_HOR,  0,   0, LINE_VER, 0, 0  ],	# + crossing

  EDGE_S_E()		=> [ NONE,  LINE_VER,   0, 0.5, LINE_HOR, 0.5, 0 ],	# |_    corner (N to E)
  EDGE_N_W()		=> [ NONE,  LINE_VER,   0, 0.5, LINE_HOR, 0, 0.5 ],	# _|    corner (N to W)
  EDGE_N_E()		=> [ NONE,  LINE_VER, 0.5,   0, LINE_HOR, 0.5, 0 ],	# ,-    corner (S to E)
  EDGE_S_W()		=> [ NONE,  LINE_VER, 0.5,   0, LINE_HOR, 0, 0.5 ],	# -,    corner (S to W)

 };

sub _svg_arrow
  {
  my ($self, $att_txt, $x, $y, $type, $dis, $indent) = @_;

  my $w = $self->{w};
  my $h = $self->{h};

  my ($x1,$x2, $y1,$y2);

  my $svg = "$indent<use$att_txt xlink:href=\"#ah\" ";

  if ($type == NORTH)
    {
    $x1 = $x + $w / 2;		# the arrow tip
    $dis *= $h if $dis < 1;
    $y1 = $y + $dis;

    $svg .= "transform=\"translate($x1 $y1) rotate(-90)\"";
    }
  elsif ($type == SOUTH)
    {
    $x1 = $x + $w / 2;		# the arrow tip
    $dis *= $h if $dis < 1;
    $y1 = $y + $h - $dis;

    $svg .= "transform=\"translate($x1 $y1) rotate(90)\"";
    }
  elsif ($type == WEST)
    {
    $dis *= $w if $dis < 1;
    $x1 = $x + $dis;		# the arrow tip
    $y1 = $y + $h / 2;

    $svg .= "transform=\"translate($x1 $y1) rotate(180)\"";
    }
  else	# $type == EAST
    {
    $dis *= $w if $dis < 1;
    $x1 = $x + $w - $dis;		# the arrow tip
    $y1 = $y + $h / 2;
    $svg .= "x=\"$x1\" y=\"$y1\"";
    }
  $svg .= "/>\n";

  $svg;
  }

sub _svg_line_straight
  {
  # Generate SVG tags for a vertical/horizontal line, bounded by (x,y), (x+w,y+h).
  # $l and $r shorten the line left/right, or top/bottom, respectively. If $l/$r < 1,
  # in % (aka $l * w), otherwise in units.
  my ($self, $att_txt, $x, $y, $type, $l, $r, $indent) = @_;

  my $w = $self->{w};
  my $h = $self->{h};

  my ($x1,$x2, $y1,$y2, $x3, $x4, $y3, $y4);

  my $ltype = $type & LINE_MASK;
  if ($ltype == LINE_HOR)
    {
    $l *= $w if $l < 1;
    $r *= $w if $r < 1;
    $x1 = $x + $l; $x2 = $x + $w - $r;
    $y1 = $y + $h / 2; $y2 = $y1;
    if (($type & LINE_DOUBLE) != 0)
      {
      $y1--; $y2--; $y3 = $y1 + 2; $y4 = $y3;
      $x1 += 1; $x2 -= 2;
      $x3 = $x1; $x4 = $x2;
      }
    }
  else
    {
    $l *= $h if $l < 1;
    $r *= $h if $r < 1;
    $x1 = $x + $w / 2; $x2 = $x1;
    $y1 = $y + $l; $y2 = $y + $h - $r;
    if (($type & LINE_DOUBLE) != 0)
      {
      $x1--; $x2--; $x3 = $x1 + 2; $x4 = $x3;
      $y1 += 1; $y2 -= 1;
      $y3 = $y1; $y4 = $y2;
      }
    }

  my $txt = 
  "$indent<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"$att_txt />\n";

  # for a double line
  if (defined $x3)
    {
    $txt .=
     "$indent<line x1=\"$x3\" y1=\"$y3\" x2=\"$x4\" y2=\"$y4\"$att_txt />\n";
    }
  $txt;
  }

#############################################################################
#############################################################################

my $dimensions = {
  EDGE_SHORT_E()	=> [ 4, 1 ],
  EDGE_SHORT_N()	=> [ 1, 4 ],
  EDGE_SHORT_W()	=> [ 4, 1 ],
  EDGE_SHORT_S()	=> [ 1, 4 ],

  EDGE_START_E()	=> [ 4, 1 ],	# |--	starting-point
  EDGE_START_N()	=> [ 1, 4 ],	# |	starting-point
  EDGE_START_W()	=> [ 4, 1 ],	# --|	starting-point
  EDGE_START_S()	=> [ 1, 4 ],	# |	starting-point

  EDGE_END_E()		=> [ 4, 1 ],	# -->	end-point
  EDGE_END_N()		=> [ 1, 4 ],	# ^	end-point
  EDGE_END_W()		=> [ 4, 1 ],	# <--	end-point
  EDGE_END_S()		=> [ 1, 4 ],	# v	end-point

  EDGE_VER()		=> [ 1, 4 ],
  EDGE_HOR()		=> [ 4, 1 ],

  EDGE_CROSS()		=> [ 2, 2 ],

  EDGE_N_E()		=> [ 2, 2 ],	# |_    corner (N to E)
  EDGE_N_W()		=> [ 2, 2 ],	# _|    corner (N to W)
  EDGE_S_E()		=> [ 2, 2 ],	# ,-    corner (S to E)
  EDGE_S_W()		=> [ 2, 2 ],	# -,    corner (S to W)

 };

sub _correct_size_svg
  {
  my ($self,$format) = @_;

  my $em = Graph::Easy::EM;		# multiplication factor chars * em = units (pixels)

  return if defined $self->{w};

  #my $border = $self->{edge}->attribute('border-style') || 'none';

  # set the minimum width/height
  my $type = $self->{type} & EDGE_TYPE_MASK();
  my $dim = $dimensions->{$type} || [ 2, 2 ];
  ($self->{w}, $self->{h}) = ($dim->[0] * $em, $dim->[1] * $em);
  }

#############################################################################
#############################################################################

sub _svg_attributes
  {
  # Return a hash with attributes for the cell.
  my ($self) = @_;

  my $att = {};

  $att->{stroke} = $self->attribute('color') || 'black';
  $att->{'stroke-width'} = 1;

  my $style = $self->{style};
  if ($style ne 'solid')				# solid line
    {
    $att->{'stroke-dasharray'} = $strokes->{$style}
     if exists $strokes->{$style};
    }

  $att;
  }

sub as_svg
  {
  my ($self,$x,$y, $indent) = @_;

  my $em = Graph::Easy::EM;		# multiplication factor chars * em = units (pixels)

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes();
  
  # set a potential title
  my $title = $self->title();
  $att->{title} = $title if $title ne '';

  my $att_txt = $self->_svg_attributes_as_txt($att);

  my $type = $self->{type} & EDGE_TYPE_MASK();

  my $edge = $self->{edge};
  my $from = $edge->{from}->{name};
  my $to = $edge->{to}->{name};
  my $svg = "$indent<!-- edge " . edge_type($type) . ", from $from to $to -->\n";
 
  # for each line, include a SVG tag

  my $lines = [ @{$draw_lines->{$type}} ];	# make copy
  my $arrow = shift @$lines;

  while (@$lines > 0)
    {
    my ($type, $l, $r) = splice (@$lines, 0, 3);

    $type += LINE_DOUBLE if $self->{style} eq 'double';
    $svg .= $self->_svg_line_straight($att_txt, $x, $y, $type, $l, $r, $indent);
    }
  $svg .= $self->_svg_arrow($att_txt, $x, $y, $arrow, 0.1, $indent) unless $arrow == NONE;

  ###########################################################################
  # include the label/name/text if we are the label cell
 
  my $label = $self->label();

  if (($self->{type} & EDGE_LABEL_CELL()))
    {
    my $xt = int($x + $em * 0.2 + $self->{w} / 4);
    my $yt = int($y + $em + $em * 0.2);
    my $color = $att->{color} || 'black';

    $svg .= "$indent<text x=\"$xt\" y=\"$yt\" style=\"font-size:$em\" fill=\"$color\">$label</text>\n";
    }

  $svg. "\n";
  }

