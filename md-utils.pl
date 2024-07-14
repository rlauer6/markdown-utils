#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Cwd;
use Config::Tiny;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename;
use Getopt::Long qw(:config no_ignore_case auto_abbrev);
use Readonly;
use Pod::Usage qw(pod2usage);

use Markdown::Render;

our $VERSION = $Markdown::Render::VERSION;

Readonly our $EMPTY => q{};
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

########################################################################
sub version {
########################################################################
  my ($name) = File::Basename::fileparse( $PROGRAM_NAME, qr/[.][^.]+$/xsm );

  print "$name $VERSION\n";

  return;
}

########################################################################
sub get_git_user {
########################################################################
  my ( $git_user, $git_email );

  for ( ( getcwd . '.git/config' ), "$ENV{HOME}/.gitconfig" ) {
    next if !-e $_;

    my $config = eval { Config::Tiny->read($_); };

    ( $git_user, $git_email ) = @{ $config->{user} }{qw(name email)};

    last if $git_user && $git_email;
  }

  return ( $git_user, $git_email );
}

# +------------------------ +
# | MAIN SCRIPT STARTS HERE |
# +------------------------ +

my %options;

my @options_spec = qw(
  body|B!
  both|b
  css=s
  debug
  engine=s
  help
  infile=s
  mode=s
  no-title
  outfile=s
  raw|R
  render|r
  title=s
  version
  nocss|N
);

GetOptions( \%options, @options_spec )
  or croak 'could not parse options';

$options{body} //= $TRUE;

if ( $options{raw} ) {
  $options{body} = $FALSE;
}

if ( exists $options{help} ) {
  pod2usage(0);
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

my ( $git_user, $git_email ) = get_git_user();

$options{git_user}  = $git_user  // $EMPTY;
$options{git_email} = $git_email // $EMPTY;

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

=head1 NAME

md-utils - Render markdown as HTML

=head1 SYNOPSIS

  md-utils [options] [markdown-file]

=head1 DESCRIPTION

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

=over

=item *

Add C<@TOC@> where you want to see your TOC.

=item *

Add C<@TOC_BACK@> to insert an internal link to TOC.

=item *

Add C<@DATE(I<format-str>)@> where you want to see a formatted date.

=item *

Add C<@GIT_USER@> where you want to see your git user name.

=item *

Add C<@GIT_EMAIL@> where you want to see your git email address.

=item *

Use the --render option to render the HTML for the markdown

=back

=head1 EXAMPLES

 md-utils README.md.in > README.md

 md-utils -r README.md.in

=head1 OPTIONS

=over

=item B<-B>, B<--body>

Default is to add body tag, use --nobody to prevent.

=item B<-b>, B<--both>

Interpolates intermediate file and renders HTML.

=item B<-c>, B<--css>

CSS file.

=item B<-e>, B<--engine>

Engine to use, options: github, text_markdown (default: github).

=item B<-h>, B<--help>

Help.

=item B<-i>, B<--infile>

Input file, default: STDIN

=item B<-m>, B<--mode>

For GitHub API mode is 'gfm' or 'markdown' (default: markdown).

=item B<-n>, B<--no-title>

Do not print a title for the table of contents.

=item B<-N>, B<--nocss>

Do not add a CSS link.

=item B<-o>, B<--outfile>

Output file, default: STDOUT.

=item B<-r>, B<--render>

Render only, does NOT interpolate keywords.

=item B<-R>, B<--raw>

Return raw HTML from engine.

=item B<-t>, B<--title>

String to use for the table of contents title, default: "Table of Contents".

=item B<-v>, B<--version>

Print the version.

=back

=head1 TIPS

=over

=item *

Use C<!#> to prevent a header from being included in the table of contents.
Add your own custom "back to TOC" message C<@TOC_BACK(Back to Index)@>.

=item *

Date format strings are based on format strings supported by the Perl module
L<Date::Format>. The default format is C<%Y-%m-%d> if no format is given.

=item *

Use the --nobody tag to return the HTML without the
C<< <html><body></body></html> >> wrapper. --raw mode will also return HTML
without wrapper.

=back

=head1 SEE ALSO

L<Markdown::Render>

=head1 AUTHOR AND LICENSE

Rob Lauer - rlauer6@comcast.net

This program is free software; you can use it and/or distribute it under the
same terms as Perl itself.

=cut
