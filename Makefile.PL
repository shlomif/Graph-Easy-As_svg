use 5.006001;
use ExtUtils::MakeMaker;
use strict;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, 'make dist' will not override 'META.yml'.");
    return $self->SUPER::metafile_target(@_);
  };

  my $node = new YAML::Node {};

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'gpl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

WriteMakefile(
    NAME		=> 'Graph::Easy::As_svg',
    VERSION_FROM	=> 'lib/Graph/Easy/As_svg.pm', # finds $VERSION
    PREREQ_PM		=> {
	'Graph::Easy' => 0.36,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Graph/Easy/As_svg.pm', # retrieve abstract from module
       AUTHOR         => 'Tels <nospam-abuse@bloodgate.com>') : ()),
    PREREQ_FATAL	=> 1,  # can't work w/o proper prereqs
);
