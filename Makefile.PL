
require 5.008001;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Get most of the details from the primary module
all_from	'lib/Graph/Easy/As_svg.pm';

requires	'Graph::Easy'	=> 0.63;
requires	'Image::Info'	=> 1.28;
 
build_requires	'Test::More'	=> 0.62;

license		'gpl'; 

# Do not index these
no_index	directory	=> 'examples';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
