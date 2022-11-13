#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use File::Basename;
use Getopt::Long;
use Markdown::Render;

our $VERSION = $Markdown::Render::VERSION;

########################################################################
sub version {
########################################################################
  my ($name) = File::Basename::fileparse( $PROGRAM_NAME, qr/[.][^.]+$/xsm );

  print "$name $VERSION\n";

  return;
}

########################################################################
sub usage {
########################################################################
  print <<'END_OF_USAGE';
usage md-utils options [markdown-file]

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

 - Add @TOC@ where you want to see your TOC.
 - Add @TOC_BACK@ to insert an internal link to TOC
 - Add @DATE(format-str)@ where you want to see a formatted date
 - Add @GIT_USER@ where you want to see your git user name
 - Add @GIT_EMAIL@ where you want to see your git email address
 - Use the --render option to render the HTML for the markdown using the GitHub API

Examples:
---------
 md-utils-toc.pl README.md.in > README.md

 md-utils-toc.pl -r README.md.in

Options
-------
-i, --infile    input file, default: STDIN
-o, --outfile   outfile, default: STDOUT
-h              help
-r, --render    render markdown via GitHub API
-b, --both      interpolates intermediate file and renders HTML
-c, --css       css file
-v, --version   version
-n, --no-title  do not print a title for the TOC
-t, --title     string to use for a custom title, default: "Table of Contents"

Tips
----
* Use !# to prevent a header from being include in the table of contents.
  Add your own custom back to TOC message @TOC_BACK(Back to Index)@

* Date format strings are based on format strings supported by the Perl
  module 'Date::Format'.  The default format is %Y-%m-%d if not format is given.

END_OF_USAGE
  return;
}

# +------------------------ +
# | MAIN SCRIPT STARTS HERE |
# +------------------------ +

my %options;

my @options_spec = qw(
  infile=s outfile=s help render css=s
  no-title title=s  debug version both
);

GetOptions( \%options, @options_spec )
  or croak 'could not parse options';

if ( exists $options{help} ) {
  usage;
  exit 0;
}

if ( exists $options{version} ) {
  version;
  exit 0;
}

$options{no_title} = delete $options{'no-title'};

my $markdown;

if ( !$options{infile} ) {

  if (@ARGV) {
    $options{infile} = shift @ARGV;
  }
  elsif ( !-t STDIN ) {  ## no critic (ProhibitInteractiveTest)
    local $RS = undef;

    my $fh = *STDIN;

    $markdown = <$fh>;
  }
}

my $md = Markdown::Render->new( %options, markdown => $markdown );

my $ofh = *STDOUT;

if ( exists $options{outfile} ) {
  open $ofh, '>', $options{outfile}  ## no critic (RequireBriefOpen)
    or croak "could not open output file\n";
}

eval {
  if ( $options{both} ) {
    $md->finalize_markdown->render_markdown;
    $md->print_html( %options, fh => $ofh );
  }
  elsif ( $options{render} ) {
    $md->render_markdown;
    $md->print_html( %options, fh => $ofh );
  }
  else {
    $md->finalize_markdown;
    print {$ofh} $md->get_markdown;
  }
};

croak "ERROR: $EVAL_ERROR"
  if $EVAL_ERROR;

close $ofh;

exit 0;

__END__
