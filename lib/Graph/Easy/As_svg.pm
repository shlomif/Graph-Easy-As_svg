#############################################################################
# output the a Graph::Easy as SVG (Scalable Vector Graphics)
#
# (c) by Tels 2004-2005.
#############################################################################

package Graph::Easy::As_svg;

use vars qw/$VERSION/;

$VERSION = '0.14';

use strict;

sub _text_length
  {
  # Take a string, and return it's length, based on the fontsize and the
  # contents ("iii" is shorter than "WWW")
  my ($em, $text) = @_;

  # For each len entry, count how often it matches the string
  # if it matches 2 times "[Ww]", and 3 times "[i]" then we have
  # (X - (2+3)) * EM + 2*$W*EM + 3*$I*EM where X is length($text), and
  # $W and $I are sizes of "[Ww]" and "[i]", respectively.

  my $count = length($text);
  my $len = 0; my $match;

  $match = $text =~ tr/'`//;
  $len += $match * 0.25 * $em; $count -= $match;

  $match = $text =~ tr/Iijl!.,;:\|//;
  $len += $match * 0.33 * $em; $count -= $match;

  $match = $text =~ tr/"Jft\(\)\[\]\{\}//;
  $len += $match * 0.4 * $em; $count -= $match;

  $match = $text =~ tr/?//;
  $len += $match * 0.5 * $em; $count -= $match;

  $match = $text =~ tr/crs_//;
  $len += $match * 0.55 * $em; $count -= $match;

  $match = $text =~ tr/BEFLPaevyz\\\/-//;
  $len += $match * 0.6 * $em; $count -= $match;

  $match = $text =~ tr/Zbdghknopqux~//;
  $len += $match * 0.65 * $em; $count -= $match;

  $match = $text =~ tr/KCVXY%//;
  $len += $match * 0.7 * $em; $count -= $match;

  $match = $text =~ tr/AHGDSNQU$&//;
  $len += $match * 0.8 * $em; $count -= $match;

  $match = $text =~ tr/wO=+<>//;
  $len += $match * 0.85 * $em; $count -= $match;

  $match = $text =~ tr/W//;
  $len += $match * 0.90 * $em; $count -= $match;

  $match = $text =~ tr/M//;
  $len += $match * 0.95 * $em; $count -= $match;

  $match = $text =~ tr/m//;
  $len += $match * 1.03 * $em; $count -= $match;

#  $match = 0; $text =~ s/[ÜÖÄüöäß]/$match++; $1/eg;	# can't handle unicode?
#  $len += $match * 0.7 * $em; $count -= $match;

  $len += $count * $em;					# anything left over is 1.0

  # return length in "characters"
  $len / $em;
  }

sub _quote_name
  {
  my $name = shift;
  my $out_name = $name;

  # "--" is not allowed inside comments:
  $out_name =~ s/--/- - /g;

  # "&", "<" and ">" will not work in comments, so quote them
  $out_name =~ s/&/&amp;/g;
  $out_name =~ s/</&lt;/g;
  $out_name =~ s/>/&gt;/g;

  $out_name;
  }

sub _quote
  {
  my $name = shift;

  my $txt = $name;

  # "&", ,'"', "<" and ">" will not work in href's
  $txt =~ s/&/&amp;/g;
  $txt =~ s/</&lt;/g;
  $txt =~ s/>/&gt;/g;
  $txt =~ s/"/&quot;/g;

  $txt;
  }

sub _sprintf
  {
  my $form = '%0.2f';

  my @rc;
  for my $x (@_)
    {
    my $y = sprintf($form, $x);

    # convert "10.00" to "10"
    $y =~ s/\.0+\z//;
    # strip tailing zeros on "0.10", but not from "100"
    $y =~ s/(\.[0-9]+?)0+\z/$1/;

    push @rc, $y;
    }

  wantarray ? @rc : $rc[0];
  }

use Graph::Easy;

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

BEGIN
  {
  *_quote = \&Graph::Easy::As_svg::_quote;
  }

sub EM
  {
  # return the height of one line in pixels, taking the font-size into account
  my $self = shift;

  # default is 14 pixels
  $self->_font_size_in_pixels( 14 );
  }

my $devs = {
  'ah' => 
     "  <!-- open arrow head -->\n  <g id="
   . '"ah" stroke-linecap="round" stroke-width="1">' . "\n"
   . '   <line x1="-8" y1="-4" x2="1" y2="0" />'. "\n"
   . '   <line x1="1" y1="0" x2="-8" y2="4" />'. "\n"
   . "  </g>\n",

  'ahc' => 
     "  <!-- closed arrow head -->\n  <g id="
   . '"ahc" stroke-linecap="round" stroke-width="1">' . "\n"
   . '   <polygon points="-8,-4, 1,0, -8,4"/>'. "\n"
   . "  </g>\n",

  'ahf' => 
     "  <!-- filled arrow head -->\n  <g id="
   . '"ahf" stroke-linecap="round" stroke-width="1">' . "\n"
   . '   <polygon points="-8,-4, 1,0, -8,4"/>'. "\n"
   . "  </g>\n",

  # point-styles
  'diamond' =>
     "  <g id="
   . '"diamond" stroke-linecap="round">' . "\n"
   . '   <polygon points="0,-6, 6,0, 0,6, -6,0"/>'. "\n"
   . "  </g>\n",
  'circle' =>
     "  <g id="
   . '"circle">' . "\n"
   . '   <circle r="6" />'. "\n"
   . "  </g>\n",
  'star' =>
     "  <g id="
   . '"star" stroke-linecap="round">' . "\n"
   . '   <line x1="0" y1="-5" x2="0" y2="5" />'. "\n"
   . '   <line x1="-5" y1="0" x2="5" y2="0" />'. "\n"
   . '   <line x1="-3" y1="-3" x2="3" y2="3" />'. "\n"
   . '   <line x1="-3" y1="3" x2="3" y2="-3" />'. "\n"
   . "  </g>\n",
  'square' =>
     "  <g id="
   . '"square">' . "\n"
   . '   <rect width="10" height="10" />'. "\n"
   . "  </g>\n",
  'dot' =>
     "  <g id="
   . '"dot">' . "\n"
   . '   <circle r="1" />'. "\n"
   . "  </g>\n",
  'cross' =>
     "  <g id="
   . '"cross" stroke-linecap="round">' . "\n"
   . '   <line x1="0" y1="-5" x2="0" y2="5" />'. "\n"
   . '   <line x1="-5" y1="0" x2="5" y2="0" />'. "\n"
   . "  </g>\n",

  # point-styles with double border
  'd-diamond' =>
     "  <g id="
   . '"d-diamond" stroke-linecap="round">' . "\n"
   . '   <polygon points="0,-6, 6,0, 0,6, -6,0"/>'. "\n"
   . '   <polygon points="0,-3, 3,0, 0,3, -3,0"/>'. "\n"
   . "  </g>\n",
  'd-circle' =>
     "  <g id="
   . '"d-circle">' . "\n"
   . '   <circle r="6" />'. "\n"
   . '   <circle r="3" />'. "\n"
   . "  </g>\n",
  'd-square' =>
     "  <g id="
   . '"d-square">' . "\n"
   . '   <rect width="10" height="10" />'. "\n"
   . '   <rect width="6" height="6" transform="translate(2,2)" />'. "\n"
   . "  </g>\n",
  };

my $strokes = {
  'dashed' => '4, 2',
  'dotted' => '2, 2',
  'dot-dash' => '2, 2, 4, 2',
  'dot-dot-dash' => '2, 2, 2, 2, 4, 2',
  'double-dash' => '4, 2',
  'bold-dash' => '4, 2',
  };

sub _svg_use_def
  {
  # mark a certain def as used (to output it's definition later)
  my ($self, $def_name) = @_;

  $self->{_svg_defs}->{$def_name} = 1;
  }

sub text_styles_as_svg
  {
  my $self = shift;

  my $style = '';
  my $ts = $self->text_styles();

  $style .= ' font-style="italic"' if $ts->{italic};
  $style .= ' font-weight="bold"' if $ts->{bold};

  if ($ts->{underline} || $ts->{none} || $ts->{overline} || $ts->{'line-through'})
    {
    # XXX TODO: HTML does seem to allow only one of them
    my @s;
    foreach my $k (qw/underline overline line-through none/)
      {
      push @s, $k if $ts->{$k};
      }
    my $s = join(' ', @s);
    $style .= " text-decoration=\"$s\"" if $s;
    }

  # XXX TODO: this will needless include the font-size if set via
  # "node { font-size: X }:

  my $fs = $self->_font_size_in_pixels( 14 ); $fs = '' if $fs eq '14';

  # XXX TODO:
  # the 'style="font-size:XXpx"' is nec. for Batik 1.5 (Firefox and Opera also
  # handle 'font-size="XXpx"'):

  $style .= " style=\"font-size:${fs}px\"" if $fs;

  $style;
  }

sub _svg_text
  { 
  # create a text via <text> at pos x,y, indented by "$indent"
  my ($self, $label, $color, $em, $indent, $x, $y, $style) = @_;

  $label =~ s/\s*\\n\s*/\n/g;			# insert real newlines

  # quote "<" and ">" 
  $label =~ s/&/&amp;/g;
  $label =~ s/>/&gt;/g;
  $label =~ s/</&lt;/g;

  my @lines = split/\n/,$label;			# split into lines

  # We can't just join them togeter with 'x=".." dy="1em"' because Firefox 1.5
  # doesn't support this (Batik does, tho). So calculate x and y on each tspan:
  if (@lines > 1)
    {
    my $dy = $y;
    $label = "$indent$indent\n<tspan y=\"$dy\">";
    $dy += $em;
    for my $i (0 .. @lines - 1)
      {
      my $join = "</tspan>\n$indent$indent<tspan x=\"$x\" y=\"$dy\">"; $dy += $em;
      $label .= $lines[$i] . $join;
      }
    $label .= "</tspan>\n$indent";
    }

  my $fs; $fs = $self->text_styles_as_svg() if $label ne '';
  $fs = '' unless defined $fs;

  my $link = _quote($self->link());

  # For an edge, the default stroke is black, but this will render a black
  # outline around colored text. So disable the stroke with "non".
  my $stroke = ''; $stroke = ' stroke="none"' if ref($self) =~ /Edge/;

  $style = '' unless defined $style;

  my $svg = "$indent<text class=\"text\" x=\"$x\" y=\"$y\"$fs fill=\"$color\"$stroke$style>$label</text>\n";

  if ($link ne '')
    {
    # although the title is already included on the outer shape, we need to
    # add it to the link, too (for shape: none, and some user agents like
    # FF 1.5 display the title only while outside the text-area)
    my $title = _quote($self->title()); $title = ' xlink:title="' . $title . '"' if $title ne '';
    $svg = $indent . "<a xlink:href=\"$link\"$title>\n$indent" . $svg .
           $indent . "</a>\n";
    }

  $svg . "\n"
  }

sub _as_svg
  {
  # convert the graph to SVG
  my ($self, $options) = @_;

  # set the info fields to defaults
  $self->{svg_info} = { width => 0, height => 0 };

  $self->layout() unless defined $self->{score};

  my ($rows,$cols,$max_x,$max_y,$cells) = $self->_prepare_layout('svg');

  my $txt;

  if ($options->{standalone})
    {
    $txt .= <<EOSVG
<?xml version="1.0" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

EOSVG
;
    }

  my $em = $self->EM();

  # XXX TODO: that should use the padding/margin attribute from the graph
  my $xl = int($em); my $yl = int($em);
  my $xr = int($em); my $yr = int($em);

  my $mx = $max_x + $xl + $xr;
  my $my = $max_y + $yl + $yr;

  # we need both xmlns= and xmlns:xlink to make Firefix 1.5 happy :-(
  $txt .=
#     '<svg viewBox="0 0 ##MX## ##MY##" width="##MX##" height="##MY##" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
     '<svg width="##MX##" height="##MY##" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
    ."\n<!-- Generated at " . scalar localtime() . " by:\n  " .
     "Graph::Easy v$Graph::Easy::VERSION\n  Graph::Easy::As_svg v$Graph::Easy::As_svg::VERSION\n -->\n\n";

  my $title = _quote($self->title());

  $txt .= " <title>$title</title>\n" if $title ne '';

  $txt .= " <defs>\n##devs##";

  # clear used definitions
  $self->{_svg_defs} = {};

  # which attributes must be output as what name:
  my $mutator = {
    background => 'fill',
    'text-align' => 'text-anchor',
    'color' => 'stroke',
    };
  my $skip = qr/^(
   arrow-style|
   (auto)?(link|title)|
   border-color|
   border-style|
   border-width|
   border|
   color|
   cols|
   font-family|
   label|
   label-color|
   linkbase|
   line-height|
   letter-spacing|
   margin.*|
   nodeclass|
   padding.*|
   rows|
   size|
   style
   shape|
   title|
   text-align|
   text-style|
   width|
   rotate|
   )\z/x;

  my $overlay = {
    edge => {
      "stroke" => 'black',
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

  ###########################################################################
  # prepare graph label output

  my $label = $self->label();
  my $lp = 'top';

  if ($label ne '')
    {
    $lp = $self->attribute('label-pos') || 'top';

    $my += $em * 2;
    }

  ###########################################################################
  # output the graph's background and border

  {
  my $bg = $self->attribute('fill'); $bg = 'white' unless defined $bg; 
  my $br = $self->attribute('border-style'); $br = '' unless defined $br;
  my $cl = $self->attribute('border-color'); $cl = 'black' unless defined $cl;
  my $bw = $self->attribute('border-width'); $bw = '1' unless defined $bw;

  if ($bg ne 'white' || $br ne '' || $cl ne 'black')
    {
    my $d = '';
    $d = ' stroke-dasharray="' . $strokes->{$br} .'"' if exists $strokes->{$br};

    $txt .= '<!-- background with border -->' .
          "\n<rect x=\"$xl\" y=\"$yl\" width=\"$mx\" height=\"$my\" fill=\"$bg\"$d stroke=\"$cl\" stroke-width=\"$bw\" />\n\n";

    # Provide some padding arund the graph to avoid that the border sticks
    # very close to the edge
    $xl += $em;
    $yl += $em;

    $mx += $em * 2;
    $my += $em * 2;
    }
  }

  ###########################################################################
  # adjust space for the graph label and output the label

  if ($label ne '')
    {
    my $y = $yl + $em; $y = $my - 2 * $em if $lp eq 'bottom';

    $txt .= "<!-- graph label -->\n" .
            Graph::Easy::Node::_svg_text($self, $label,
		$self->attribute('color') || 'black', $em, '', $mx / 2, $y);

    # push content down if label is at top
    $yl += $em * 2 if $lp eq 'top';
    }

  # XXX: output cells that belong to one edge/node in order, e.g.
#  for my $n (@nodes)
#     {
#     # output node      
#    for my $e (@edges)
#       {
#       # output edges leaving this node  
#       }
#     }

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
      $txt .= $n->as_svg($x,$y,' ');			# output cell, indented
      $txt =~ s/\n\z/<\/g>\n\n/;
      }
    }

  # include the used definitions into <devs>
  my $d = '';
  for my $key (keys %{$self->{_svg_defs}})
    {
    $d .= $devs->{$key};
    }
  $txt =~ s/##devs##/$d/;

  $txt =~ s/##MX##/$mx/;
  $txt =~ s/##MY##/$my/;

  $txt .= "</svg>";			# finish

  $txt .= "\n" if $options->{standalone};

  # set the info fields:
  $self->{svg_info}->{width} = $mx; 
  $self->{svg_info}->{height} = $my; 

  $txt;
  }

=pod

=head1 NAME

Graph::Easy::As_svg - Output a Graph::Easy as Scalable Vector Graphics (SVG)

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');

	print $graph->as_svg_file();


=head1 DESCRIPTION

C<Graph::Easy::As_svg> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a SVG text.

X<graph::easy>
X<graph>
X<drawing>
X<svg>
X<scalable>
X<vector>
X<grafics>

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

x<tels>

=cut

package Graph::Easy::Node::Cell;

sub as_svg
  {
  return '';
  }

package Graph::Easy::Node;

BEGIN
  {
  *_sprintf = \&Graph::Easy::As_svg::_sprintf;
  *_quote = \&Graph::Easy::As_svg::_quote;
  }

sub _svg_dimensions
  {
  # Returns the dimensions of the node/cell derived from the label (or name) in characters.
  my $self = shift;

  my $label = $self->{att}->{label}; $label = $self->{name} unless defined $label;
  $label = '' unless defined $label;

  $label =~ s/\\n/\n/g;

  my @lines = split /\n/, $label;
  my $w = 0; my $h = scalar @lines;
  my $em = $self->EM();
  foreach my $line (@lines)
    {
    $line =~ s/^\s+//; $line =~ s/\s+$//;               # rem spaces
    my $line_length = Graph::Easy::As_svg::_text_length($em, $line);
    $w = $line_length if $line_length > $w;
    }
  ($w,$h);
  }

sub _svg_background
  {
  # draw the background for this node/cell, if nec.
  my ($self, $svg, $x, $y, $indent) = @_;

  my $bg = $self->background();

  if ($bg ne 'inherit' && $bg ne '')
    {
    my $w = $self->{w};
    my $h = $self->{h};
    $$svg .= "$indent<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" fill=\"$bg\" />\n";
    }

  }

BEGIN
  {
  *EM = \&Graph::Easy::EM;
  *text_styles_as_svg = \&Graph::Easy::text_styles_as_svg;
  *_svg_text = \&Graph::Easy::_svg_text;
  }

sub as_svg
  {
  # output a node as SVG
  my ($self,$x,$y,$indent) = @_;

  my $name = $self->{att}->{label}; $name = $self->{name} unless defined $name;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes($x,$y);
  
  my $shape = $att->{shape};				# rect, circle etc
  delete $att->{shape};

  return '' if $shape eq 'invisible';

  # set a potential title
  my $title = _quote($self->title());
  $att->{title} = $title if $title ne '';

  my $s = $self->attribute('shape') || 'rectangle';

  my $out_name = Graph::Easy::As_svg::_quote_name($name);
  my $svg = "$indent<!-- $out_name, $s -->\n";

  # render the background, except for "rect" where it is not visible
  $self->_svg_background(\$svg, $x,$y, $indent) if $shape ne 'rect';

  my $bs = $self->attribute('border-style') || '';

  my $xt = int($x + $self->{w} / 2);
  my $yt = int($y + $self->{h} / 2);

  # render the node shape itself
  if ($shape eq 'point')
    {
    # include the point-style
    my $s = $self->attribute('point-style') || 'star';
    $s = 'd-' . $s if $bs =~ /^double/ && $s =~ /^(square|diamond|circle)\z/;

    my $a = { };
    for my $key (keys %$att)
      {
      $a->{$key} = $att->{$key};
      }
    $a->{stroke} = $self->attribute('border-color') || 'black';
    $a->{fill} = $a->{stroke} if $s eq 'dot';

    my $att_txt = $self->_svg_attributes_as_txt($a, $xt, $yt);

    # center a square point-node
    $yt -= 5 if $s =~ 'square';
    $xt -= 5 if $s =~ 'square';

    $self->{graph}->_svg_use_def($s);

    $svg .= "$indent<use$att_txt xlink:href=\"#$s\" x=\"$xt\" y=\"$yt\"/>\n\n";
    }
  else
    {
    if ($shape ne 'none')
      {

      # If we need to draw the border shape twice, put common attributes on
      # a <g> around it. (In the case there is only "stroke: #000000;" it will
      # waste 4 bytes, but in all other cases save quite a few.

      my $group = {};
      if ($bs =~ /^double/)
        {
        for my $a (qw/ fill stroke stroke-dasharray/)
          {
          $group->{$a} = $att->{$a} if exists $att->{$a}; delete $att->{$a};
          }
        }

      my $att_txt = $self->_svg_attributes_as_txt($att, $xt, $yt) || '';

      my $shape_svg = "$indent<$shape$att_txt />\n";

      # if border-style is double, do it again, sam.
      if ($bs =~ /^double/)
        {
        my $group_txt = $self->_svg_attributes_as_txt($group, $xt, $yt);

        $shape_svg = "$indent<g$group_txt>\n$indent" . $shape_svg;

        my $att = $self->_svg_attributes($x,$y, 3);
        for my $a (qw/ fill stroke stroke-dasharray/)
          {
          delete $att->{$a};
          }

        my $shape = $att->{shape};				# circle etc
        delete $att->{shape};

        my $att_txt = $self->_svg_attributes_as_txt( $att, $xt, $yt );

        $shape_svg .= "$indent$indent<$shape$att_txt />\n";

        $shape_svg .= "$indent</g>\n";				# close group
        }
      $svg .= $shape_svg;
      }

    ###########################################################################
    # include the label/name/text

    my $xt = int($x + $em * 0.05 + $self->{w} / 2);

    my $label = $self->label();

    # count lines
    my $lines = -1; $label =~ s/\\n/ $lines++; '\\n' /eg; 

    $lines /= 2;
    my $yt = int($y + $self->{h} / 2 - $em * $lines - $em * 0.1);

    $yt += $self->{h} * 0.3 if $s =~ /^(triangle|trapezium)\z/;
    $yt -= $self->{h} * 0.3 if $s =~ /^inv(triangle|trapezium)\z/;
  
    my $color = $self->attribute('color') || 'black';

    $svg .= $self->_svg_text($label, $color, $em, $indent, $xt, $yt);
    }

  $svg;
  }

sub _svg_attributes
  {
  # Return a hash with attributes for the node, like "x => 1, y => 1, w => 1, h => 1"
  # Especially usefull for shapes other than boxes.
  my ($self,$x,$y, $sub) = @_;

  # subtract factor, 0 or 2 for border-style: double
  $sub ||= 0;

  my $att = {};

  my $shape = $self->shape();

  my $em = $self->EM();
  my $border_width = Graph::Easy::_border_width_in_pixels($self,$em);

  # subtract half of our border-width because the border-center would otherwise
  # be on the node's border-line and thus extending outward:
  my $bw2 = $border_width / 2; $sub += $bw2;

  my $w2 = $self->{w} / 2;
  my $h2 = $self->{h} / 2;

  # center
  my $cx = $x + $self->{w} / 2;
  my $cy = $y + $self->{h} / 2;

  my $double = 0; $double = 1 if ($self->attribute('border-style') || '') eq 'double';

  my $x2 = $x + $self->{w} - $sub;
  my $y2 = $y + $self->{h} - $sub;

  $x += $sub; $y += $sub;

  my $sub3 = $sub / 3;		# 0.333 * $sub
  my $sub6 = 2 * $sub / 3;	# 0.666 * $sub

  if ($shape =~ /^(point|none)\z/)
    {
    }
  elsif ($shape eq 'circle')
    {
    $att->{cx} = $cx;
    $att->{cy} = $cy;
    $att->{r} = $self->{minw} > $self->{minh} ? $self->{minw} : $self->{minh};
    $att->{r} /= 2;
    $att->{r} -= $sub;
    }
  elsif ($shape eq 'parallelogram')
    {
    my $xll = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xrl = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl = _sprintf($x + $sub6);
    my $xr = _sprintf($x2 - $sub6);

    $shape = "polygon points=\"$xll,$y, $xr,$y, $xrl,$y2, $xl,$y2\"";
    }
  elsif ($shape eq 'trapezium')
    {
    my $xl = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xr = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl1 = _sprintf($x + $sub3);
    my $xr1 = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y, $xr,$y, $xr1,$y2, $xl1,$y2\"";
    }
  elsif ($shape eq 'invtrapezium')
    {
    my $xl = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xr = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl1 = _sprintf($x + $sub3);
    my $xr1 = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl1,$y, $xr1,$y, $xr,$y2, $xl,$y2\"";
    }
  elsif ($shape eq 'diamond')
    {
    my $x1 = $cx;
    my $y1 = $cy;

    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y1, $x1,$y, $xr,$y1, $x1,$y2\" stroke-linecap=\"round\"";
    }
  elsif ($shape eq 'house')
    {
    my $x1 = $cx;
    my $y1 = _sprintf($y - $sub3 + $self->{h} * 0.333);

    $shape = "polygon points=\"$x1,$y, $x2,$y1, $x2,$y2, $x,$y2, $x,$y1\"";
    }
  elsif ($shape eq 'pentagon')
    {
    my $x1 = $cx;
    my $x11 = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub3 - $self->{w} * 0.25);
    my $y1 = _sprintf($y - $sub6 + $self->{h} * 0.333);
    
    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$x1,$y, $xr,$y1, $x12,$y2, $x11,$y2, $xl,$y1\"";
    }
  elsif ($shape eq 'invhouse')
    {
    my $x1 = $cx;
    my $y1 = _sprintf($y - (1.4 * $sub) + $self->{h} * 0.666);

    $shape = "polygon points=\"$x,$y, $x2,$y, $x2,$y1, $x1,$y2, $x,$y1\"";
    }
  elsif ($shape eq 'septagon')
    {
    my $x15 = $cx;
    
    my $x11 = _sprintf($x2 + $sub3 - $self->{w} * 0.10);
    my $x14 = _sprintf($x - $sub3 + $self->{w} * 0.10);

    my $y11 = _sprintf($y - $sub3 + $self->{h} * 0.15);
    my $y13 = _sprintf($y2 + 0.85 * $sub - $self->{h} * 0.40);

    my $x12 = _sprintf($x2 + $sub6 - $self->{w} * 0.25);
    my $x13 = _sprintf($x - $sub6 + $self->{w} * 0.25);
    
    my $xl = _sprintf($x - 0.15 * $sub);
    my $xr = _sprintf($x2 + 0.15 * $sub);

    $shape = "polygon points=\"$x15,$y, $x11,$y11, $xr,$y13, $x12,$y2, $x13,$y2, $xl,$y13, $x14, $y11\"";
    }
  elsif ($shape eq 'octagon')
    {
    my $x11 = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub3 - $self->{w} * 0.25);
    my $y11 = _sprintf($y - $sub6 + $self->{h} * 0.25);
    my $y12 = _sprintf($y2 + $sub6 - $self->{h} * 0.25);

    my $xl = _sprintf($x + $sub * 0.133);
    my $xr = _sprintf($x2 - $sub * 0.133);

    $shape = "polygon points=\"$xl,$y11, $x11,$y, $x12,$y, $xr,$y11, $xr,$y12, $x12,$y2, $x11,$y2, $xl,$y12\"";
    }
  elsif ($shape eq 'hexagon')
    {
    my $y1 = $cy;
    my $x11 = _sprintf($x - $sub6 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub6 - $self->{w} * 0.25);

    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y1, $x11,$y, $x12,$y, $xr,$y1, $x12,$y2, $x11,$y2\"";
    }
  elsif ($shape eq 'triangle')
    {
    my $x1 = $cx;

    my $xl = _sprintf($x + $sub);
    my $xr = _sprintf($x2 - $sub);

    my $yd = _sprintf($y2 + ($sub * 0.2 ));

    $shape = "polygon points=\"$x1,$y, $xr,$yd, $xl,$yd\"";
    }
  elsif ($shape eq 'invtriangle')
    {
    my $x1 = $cx;

    my $xl = _sprintf($x + $sub);
    my $xr = _sprintf($x2 - $sub);

    my $yd = _sprintf($y - ($sub * 0.2));

    $shape = "polygon points=\"$xl,$yd, $xr,$yd, $x1,$y2\"";
    }
  elsif ($shape eq 'ellipse')
    {
    $att->{cx} = $cx;
    $att->{cy} = $cy;
    $att->{rx} = $w2 - $sub;
    $att->{ry} = $h2 - $sub;
    }
  else
    {
    if ($shape eq 'rounded')
      {
      # round corners by a fixed value
      $att->{ry} = '15';
      $att->{rx} = '15';
      $shape = 'rect';
      }
    $att->{x} = $x;
    $att->{y} = $y;
    $att->{width} = _sprintf($self->{w} - $sub * 2);
    $att->{height} = _sprintf($self->{h} - $sub * 2);
    }
  $att->{shape} = $shape;

  my $border_style = $self->attribute('border-style') || 'solid';
  my $border_color = $self->attribute('border-color') || 'black';

  $att->{'stroke-width'} = $border_width if $border_width ne '1';
  $att->{stroke} = $border_color;

  if ($border_style !~ /^(none|solid)/)
    {
    $att->{'stroke-dasharray'} = $strokes->{$border_style}
     if exists $strokes->{$border_style};
    }
  
  if ($border_style eq 'none')
    {
    delete $att->{'stroke-width'};
    delete $att->{stroke};
    }
  $att->{fill} = $self->attribute('fill') || 'white';
  delete $att->{fill} if $att->{fill} eq 'white';	# white is default

  $att->{rotate} = $self->attribute('rotate') || 0;
  $att;
  }

sub _svg_attributes_as_txt
  {
  # convert hash with attributes to text to be included in SVG tag
  my ($self, $att, $x, $y) = @_;

  my $att_line = '';				# attributes as text (cur line)
  my $att_txt = '';				# attributes as text (all)
  foreach my $e (sort keys %$att)
    {
    # skip these
    next if $e =~ /^(arrow-style|text-style|label-color|rows|cols|size|offset|origin|rotate)\z/;

    $att_line .= " $e=\"$att->{$e}\"";
    if (length($att_line) > 75)
      {
      $att_txt .= "$att_line\n  "; $att_line = '';
      }
    }

  ###########################################################################
  # include the rotation

  my $r = $att->{rotate} || 0;

  $att_line .= " transform=\"rotate($r, $x, $y)\"" if $r != 0;
  if (length($att_line) > 75)
    {
    $att_txt .= "$att_line\n  "; $att_line = '';
    }

  $att_txt .= $att_line;
  $att_txt =~ s/\n  \z//;		# avoid a "  >" on last line
  $att_txt;
  }
 
sub _correct_size_svg
  {
  # Correct {w} and {h} for the node after parsing.
  my $self = shift;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  return if defined $self->{w};

  my $shape = $self->shape();
  if ($shape eq 'point')
    {
    $self->{w} = $em * 3;
    $self->{h} = $em * 3;
    return;
    }

  my ($w,$h) = $self->_svg_dimensions();

  # XXX TODO: that should use a changable padding factor (like "0.2 em" or "4")
  $self->{w} = int($w * $em + 0.5 * $em);
  $self->{h} = int($h * $em + 0.8 * $em);

  my $border = 'none';
  $border = $self->attribute('border-style') || 'none' if $shape ne 'none';

  if ($border ne 'none')
    {
    my $bw = Graph::Easy::_border_width_in_pixels($self,$em);
    $self->{w} += $bw * 2;
    $self->{h} += $bw * 2;
    }
 
  # for triangle or invtriangle:
  $self->{w} *= 1.4 if $shape =~ /triangle/;
  $self->{h} *= 1.8 if $shape =~ /triangle|trapezium/;
  $self->{w} *= 1.2 if $shape =~ /(parallelogram|trapezium|pentagon)/;

  if ($shape =~ /^(diamond|circle|octagon|hexagon|triangle)\z/)
    {
    # the min size is either w or h, depending on which is bigger
    my $max = $self->{w}; $max = $self->{h} if $self->{h} > $max;
    $self->{h} = $max;
    $self->{w} = $max;
    }
  }
 
1;

package Graph::Easy::Edge::Cell;

BEGIN
  {
  *_sprintf = \&Graph::Easy::As_svg::_sprintf;
  *_quote = \&Graph::Easy::As_svg::_quote;
  }

#############################################################################
#############################################################################
# Line drawing code for edges

# define the line lengths for the different edge types

sub LINE_HOR () { 0x0; }
sub LINE_VER () { 0x1; }

sub LINE_MASK () { 0x0F; }
sub LINE_DOUBLE () { 0x10; }

  # edge type       line type  spacing left/top
  #				    spacing right/bottom

my $draw_lines = {

  EDGE_N_W_S()	=> [ LINE_HOR, 0.2, 0.2 ],			# v--+  loop, northwards
  EDGE_S_W_N()	=> [ LINE_HOR, 0.2, 0.2 ],			# ^--+  loop, southwards
  EDGE_E_S_W()	=> [ LINE_VER, 0.2, 0.2 ],			# [_    loop, westwards
  EDGE_W_S_E()	=> [ LINE_VER, 0.2, 0.2 ],			# _]    loop, eastwards

  EDGE_VER()	=> [ LINE_VER, 0, 0 ],				# |	vertical line
  EDGE_HOR()	=> [ LINE_HOR, 0, 0 ],				# --	vertical line

  EDGE_CROSS()	=> [ LINE_HOR, 0, 0, LINE_VER, 0, 0  ],		# + crossing

  EDGE_S_E()	=> [ LINE_VER,   0.5, 0, LINE_HOR, 0.5, 0 ],	# |_    corner (N to E)
  EDGE_N_W()	=> [ LINE_VER,   0, 0.5, LINE_HOR, 0, 0.5 ],	# _|    corner (N to W)
  EDGE_N_E()	=> [ LINE_VER,   0, 0.5, LINE_HOR, 0.5, 0 ],	# ,-    corner (S to E)
  EDGE_S_W()	=> [ LINE_VER,   0.5, 0, LINE_HOR, 0, 0.5 ],	# -,    corner (S to W)

  EDGE_S_E_W	=> [ LINE_HOR, 0, 0, LINE_VER, 0.5, 0 ],	# -,-   three-sided corner (S to W/E)
  EDGE_N_E_W	=> [ LINE_HOR, 0, 0, LINE_VER, 0, 0.5 ],	# -'-   three-sided corner (N to W/E)
  EDGE_E_N_S	=> [ LINE_VER, 0, 0, LINE_HOR, 0.5, 0 ],	#  |-   three-sided corner (E to S/N)
  EDGE_W_N_S	=> [ LINE_VER, 0, 0, LINE_HOR, 0, 0.5 ],	# -|    three-sided corner (W to S/N)
 };

sub _svg_arrow
  {
  my ($self, $att, $x, $y, $type, $dis, $indent, $s) = @_;

  my $w = $self->{w};
  my $h = $self->{h};

  my ($x1,$x2, $y1,$y2);

  # For the things to be "used" define these attributes, so if they
  # match, we can skip them, generating shorter output:

  my $DEF = { 
    "stroke-linecap" => 'round',
    };

  my $arrow_style = $att->{"arrow-style"} || '';
  my $class = "ah" . substr($arrow_style,0,1);

  my $a = {};
  for my $key (keys %$att)
    {
    next if $key =~ /^(stroke-dasharray|arrow-style|stroke-width)\z/;
    $a->{$key} = $att->{$key}
     unless exists $DEF->{$key} && $DEF->{$key} eq $att->{$key};
    }
  if ($arrow_style eq 'closed')
    {
    $a->{fill} = $self->attribute('background');
    $a->{fill} = $self->{graph}->attribute('graph', 'background') if $a->{fill} eq 'inherit';
    $a->{fill} = 'white' if $a->{fill} eq 'inherit';
    }
  elsif ($arrow_style eq 'filled')
    {
    $a->{fill} = $self->attribute('fill');
    }

  my $att_txt = $self->_svg_attributes_as_txt($a);

  $self->{graph}->_svg_use_def($class) if ref $self->{graph};

  my $ar = "$indent<use$att_txt xlink:href=\"#$class\" ";

  my $svg = '';

  my $scale = ''; $scale = "scale($s)" if $s; 

  if ($type & EDGE_END_N)
    {
    $x1 = _sprintf($x + $w / 2);		# the arrow tip
    $dis *= $h if $dis < 1;
    $y1 = _sprintf($y + $dis);

    $svg .= $ar . "transform=\"translate($x1 $y1) rotate(-90)$scale\"/>\n";
    }
  if ($type & EDGE_END_S)
    {
    $x1 = _sprintf($x + $w / 2);		# the arrow tip
    $dis *= $h if $dis < 1;
    $y1 = _sprintf($y + $h - $dis);

    $svg .= $ar . "transform=\"translate($x1 $y1) rotate(90)$scale\"/>\n";
    }
  if ($type & EDGE_END_W)
    {
    $dis *= $w if $dis < 1;
    $x1 = _sprintf($x + $dis);			# the arrow tip
    $y1 = _sprintf($y + $h / 2);

    $svg .= $ar . "transform=\"translate($x1 $y1) rotate(180)$scale\"/>\n";
    }
  if ($type & EDGE_END_E)
    {
    $dis *= $w if $dis < 1;
    $x1 = _sprintf($x + $w - $dis);	# the arrow tip
    $y1 = _sprintf($y + $h / 2);

    my $a = $ar . "x=\"$x1\" y=\"$y1\"/>\n";
    $a = $ar . "transform=\"translate($x1 $y1) $scale\"/>\n" if $scale;
    $svg .= $a;
    }

  $svg;
  }

sub _svg_line_straight
  {
  # Generate SVG tags for a vertical/horizontal line, bounded by (x,y), (x+w,y+h).
  # $l and $r shorten the line left/right, or top/bottom, respectively. If $l/$r < 1,
  # in % (aka $l * w), otherwise in units.
  # "$s" means there is a starting point, so the line needs to be shorter. Likewise
  # for "$e", only on the "other" side. 
  # VER: s = north, e = south, HOR: s = left, e= right
  my ($self, $x, $y, $type, $l, $r, $s, $e, $add) = @_;

  my $w = $self->{w};
  my $h = $self->{h};

  $add = '' unless defined $add;	# additinal styles?

  my ($x1,$x2, $y1,$y2, $x3, $x4, $y3, $y4);

  my $ltype = $type & LINE_MASK;
  if ($ltype == LINE_HOR)
    {
    $l += $s if $s;
    $r += $e if $e;
    $l *= $w if $l < 1;
    $r *= $w if $r < 1;
    $x1 = $x + $l; $x2 = $x + $w - $r;
    $y1 = $y + $h / 2; $y2 = $y1;
    if (($type & LINE_DOUBLE) != 0)
      {
      $y1--; $y2--; $y3 = $y1 + 2; $y4 = $y3;
      # shorten the line for end/start points
      if ($s || $e ) { $x1 += 1.5; $x2 -= 1.5; }
      $x3 = $x1; $x4 = $x2;
      }
    }
  else
    {
    $l += $s if $s;
    $r += $e if $e;
    $l *= $h if $l < 1;
    $r *= $h if $r < 1;
    $x1 = $x + $w / 2; $x2 = $x1;
    $y1 = $y + $l; $y2 = $y + $h - $r;
    if (($type & LINE_DOUBLE) != 0)
      {
      $x1--; $x2--; $x3 = $x1 + 2; $x4 = $x3;
      # shorten the line for end/start points
      if ($s || $e) { $y1 += 1.5; $y2 -= 1.5; }
      $y3 = $y1; $y4 = $y2;
      }
    }

  ($x1,$y1,$x2,$y2) = _sprintf($x1,$y1,$x2,$y2);

  my @r = ( "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" $add/>" );

  # for a double line
  push @r, "<line x1=\"$x3\" y1=\"$y3\" x2=\"$x4\" y2=\"$y4\" $add/>"
   if defined $x3;

  @r;
  }

#############################################################################
#############################################################################

my $dimensions = {
  EDGE_VER()	=> [ 1, 3 ],	# |
  EDGE_HOR()	=> [ 3, 1 ],	# -

  EDGE_CROSS()	=> [ 3, 3 ],	# +	crossing

  EDGE_N_E()	=> [ 3, 3 ],	# |_    corner (N to E)
  EDGE_N_W()	=> [ 3, 3 ],	# _|    corner (N to W)
  EDGE_S_E()	=> [ 3, 3 ],	# ,-    corner (S to E)
  EDGE_S_W()	=> [ 3, 3 ],	# -,    corner (S to W)

  EDGE_S_E_W	=> [ 3, 3 ],	# -,-   three-sided corner (S to W/E)
  EDGE_N_E_W	=> [ 3, 3 ],	# -'-   three-sided corner (N to W/E)
  EDGE_E_N_S	=> [ 3, 3 ],	#  |-   three-sided corner (E to S/N)
  EDGE_W_N_S	=> [ 3, 3 ], 	# -|    three-sided corner (W to S/N)
 };

sub _correct_size_svg
  {
  # correct the size for the edge cell
  my ($self,$format) = @_;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  return if defined $self->{w};

  #my $border = $self->{edge}->attribute('border-style') || 'none';

  # set the minimum width/height
  my $type = $self->{type} & EDGE_TYPE_MASK();
  my $dim = $dimensions->{$type} || [ 2, 2 ];
  ($self->{w}, $self->{h}) = ($dim->[0], $dim->[1]);

  # make it bigger for cells with the label
  if ($self->{type} & EDGE_LABEL_CELL)
    {
    my ($w,$h) = $self->_svg_dimensions();
    # for vertical edges, multiply $w * 2 and add 2 em
    $w = $w * 2 + 2 if ($type == EDGE_VER);
    $self->{w} += $w;
    $self->{h} += $h;
    }

  my $style = $self->{style};

  # correct for bigger arrows
  my $ac = $self->arrow_count();
  if ($ac > 0 && $style =~ /^(broad|wide)/)
    {
    my $add = 1.5; $add = 2.5 if $style =~ /^wide/;

    # if we have two arrows, double the additional space
    $add *= 2 if $ac > 1;

    $self->{w} += $add;
    }

  ($self->{w}, $self->{h}) = ($self->{w} * $em, $self->{h} * $em);
  }

#############################################################################
#############################################################################

sub _svg_attributes
  {
  # Return a hash with attributes for the cell.
  my ($self, $em) = @_;

  my $att = {};

  $att->{stroke} = $self->attribute('color') || 'black';
  delete $att->{stroke} if $att->{stroke} eq 'black';	# black is default

  $att->{'stroke-width'} = 1;

  my $style = $self->{style};
  if ($style ne 'solid')				# solid line
    {
    $att->{'stroke-dasharray'} = $strokes->{$style}
     if exists $strokes->{$style};
    }

  $att->{'stroke-width'} = 3 if $style =~ /^bold/;
  $att->{'stroke-width'} = $em / 2 if $style =~ /^broad/;
  $att->{'stroke-width'} = $em if $style =~ /^wide/;

  $att->{'arrow-style'} = $self->attribute('arrow-style') || '';
  $att;
  }

sub as_svg
  {
  my ($self,$x,$y, $indent) = @_;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes($em);
 
  # set a potential title
  my $title = _quote($self->title());
  $att->{title} = $title if $title ne '';

  my $att_txt = $self->_svg_attributes_as_txt($att);

  my $type = $self->{type} & EDGE_TYPE_MASK();
  my $end = $self->{type} & EDGE_END_MASK();
  my $start = $self->{type} & EDGE_START_MASK();

  my $edge = $self->{edge};
  my $from = Graph::Easy::As_svg::_quote_name($edge->{from}->{name});
  my $to = Graph::Easy::As_svg::_quote_name($edge->{to}->{name});
  
  my $svg = "$indent<!-- " . edge_type($type) . ", from $from to $to -->\n";

  $self->_svg_background(\$svg, $x,$y, $indent);
  # if defined $att->{background} || keys %{$self->{edge}->{groups}} > 0;

  # for each line, include one SVG tag
  my $lines = [ @{$draw_lines->{$type}} ];	# make copy

  my $style = $self->{style};

  my $cross = ($self->{type} & EDGE_TYPE_MASK) == EDGE_CROSS;	# we are a cross section?
  my $add;

  my @line_tags;
  while (@$lines > 0)
    {
    my ($type, $l, $r) = splice (@$lines, 0, 3);

    # start/end points
    my ($s,$e) = (undef,undef);

    my $bw  = $self->{w} * 0.1 + ($att->{'stroke-width'} || 1) / 3;
    my $bwe = $self->{w} * 0.1 + ($att->{'stroke-width'} || 1) / 1.8;
    my $bh = $self->{h} * 0.1 + ($att->{'stroke-width'} || 1) / 3;
    my $bhe = $self->{h} * 0.1 + ($att->{'stroke-width'} || 1) / 1.8;

    # VER: s = north, e = south, HOR: s = left, e= right
    if ($type == LINE_VER)
      {
      $e = $bhe if ($end & EDGE_END_S);
      $s = $bhe if ($end & EDGE_END_N);
      $e = $bh if ($start & EDGE_START_S);
      $s = $bh if ($start & EDGE_START_N);
      }
    else # $type == LINE_HOR
      {
      $e = $bwe if ($end & EDGE_END_E);
      $s = $bwe if ($end & EDGE_END_W);
      $e = $bw if ($start & EDGE_START_E);
      $s = $bw if ($start & EDGE_START_W);
      }

    # LINE_VER must come last
    if ($cross && $type == LINE_VER)
      {
      $style = $self->{style_ver};
      $add = ' stroke="' . $self->{color_ver} . '"' if $self->{color_ver};
      $add .= ' stroke-dasharray="' . ($strokes->{$style}||'1 0') .'"';
      }
    $type += LINE_DOUBLE if $style =~ /^double/;
    push @line_tags, $self->_svg_line_straight($x, $y, $type, $l, $r, $s, $e, $add);
    }

  # we can put the line tags into a <g> and put stroke attributes on the g,
  # this will shorten the output

  $lines = ''; my $p = "\n"; my $i = $indent;
  if (@line_tags > 1)
    {
    $lines = "$indent<g$att_txt>\n";
    $i .= $indent;
    $p = "\n$indent</g>\n"; 
    }
  else
    {
    $line_tags[0] =~ s/ \/>/$att_txt \/>/;
    }
  $lines .= $i . join("\n$i", @line_tags) . $p;

  $svg .= $lines;

  my $arrow = $end;
  # depending on end points, add the arrow
  
  my $scale = $att->{'stroke-width'}||1; 
  if ($scale < 4)
    {
    $scale = '';
    }
  else
    {
    $scale /= 4;
    }

  $svg .= $self->_svg_arrow($att, $x, $y, $arrow, 0.1, $indent, $scale) unless $arrow == 0;

  ###########################################################################
  # include the label/name/text if we are the label cell

  if (($self->{type} & EDGE_LABEL_CELL()))
    {
    my $label = $self->label(); $label = '' unless defined $label;

    if ($label ne '')
      {
      my $xt = int($x + $self->{w} / 2);
      my $yt = int($y + $em + $em * 0.2);

      my $style = '';

      # for HOR edges
      if ($type == EDGE_HOR)
        {
        # if we have only one big arrow, shift the text left/right
        my $ac = $self->arrow_count();
        my $style = $self->{style};

        if ($ac == 1)
          {
          my $shift = 0.2;
          $shift = 0.5 if $style =~ /^broad/;
          $shift = 0.8 if $style =~ /^wide/;
          # <-- edges, shift right, otherwise left
          $shift = -$shift if ($end & EDGE_END_E) != 0;
          $xt = int($xt + $em * $shift);
          }
        }
      else
        {
        # put label right of the edge
        my ($w,$h) = $self->dimensions();
        $xt = $xt + $w * $em / 2;
        $yt += $em if $self->{type} & EDGE_START_N;
        $yt -= $em if $self->{type} & EDGE_START_S;
        $style = ' text-align="left"';
        }

      my $color = $self->attribute('label-color') || '';

      # fall back to color if label-color not defined
      $color = $self->attribute('color') || 'black' if $color eq '';

      $svg .= $self->_svg_text($label, $color, $em, $indent, $xt, $yt, $style);
      }
    } 

  $svg .= "\n" unless $svg =~ /\n\n\z/;

  $svg;
  }

