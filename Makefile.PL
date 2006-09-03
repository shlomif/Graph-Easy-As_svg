
# Load the Module::Install bundled in ./inc/
use inc::Module::Install;
    
# The name of your distribution
name		'Graph-Easy-As_svg';
    
# Get most of the details from the primary module
all_from	'lib/Graph/Easy/As_svg.pm';
   
requires	'Graph::Easy'	=> 0.47;
requires	'Image::Info'	=> 1.22;
 
build_requires	'Test::More'	=> 0.42;
   
license		'gpl'; 

# Do not index these
no_index	directory	=> 'examples';
    
# Auto-install all dependencies from CPAN
auto_install;
    
# Generate the Makefile
WriteAll;
