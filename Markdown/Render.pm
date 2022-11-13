package Markdown::Render;

use strict;
use warnings;

use Data::Dumper;
use English qw(-no_match_vars);
use HTTP::Request;
use IO::Scalar;
use JSON;
use LWP::UserAgent;

our $VERSION = '1.01';

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;

__PACKAGE__->mk_accessors(
  qw(
    infile
    html
    render
    no_title
    title
    markdown
    css
    git_user
    git_email
  )
);

use Readonly;

Readonly our $GITHUB_API  => 'https://api.github.com/markdown';
Readonly our $EMPTY       => q{};
Readonly our $SPACE       => q{ };
Readonly our $TOC_TITLE   => 'Table of Contents';
Readonly our $TOC_BACK    => 'Back to Table of Contents';
Readonly our $DEFAULT_CSS => 'https://cdn.simplecss.org/simple-v1.css';

caller or __PACKAGE__->main;

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my %options = ref $args[0] ? %{ $args[0] } : @args;

  my $self = $class->SUPER::new( \%options );

  if ( !$self->get_title ) {
    $self->set_title($TOC_TITLE);
  }

  if ( $self->get_infile ) {
    open my $fh, '<', $self->get_infile
      or die 'could not open ' . $self->get_infile;

    local $RS = undef;

    $self->set_markdown(<$fh>);

    close $fh;
  }

  if ( !$self->get_css ) {
    $self->set_css($DEFAULT_CSS);
  }

  return $self;
}

########################################################################
sub toc_back {
########################################################################
  my ($self) = @_;

  my $back_link = lc $self->get_title;
  $back_link =~ s/\s/-/gxsm;

  return $back_link;
}

########################################################################
sub back_to_toc {
########################################################################
  my ( $self, $message ) = @_;

  $message //= $TOC_BACK;

  $message =~ s/[(]\"?(.*?)\"?[)]/$1/xsm;

  return sprintf '[%s](#%s)', $message, $self->toc_back;
}

########################################################################
sub finalize_markdown {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  die "no markdown yet\n"
    if !$markdown;

  my $fh = IO::Scalar->new( \$markdown );

  my $final_markdown;

  while ( my $line = <$fh> ) {
    $line =~ s/^\!\#/\#/xsm;  # ! used to prevent including header in TOC

    if ( $line =~ /\@TOC\@/xsm ) {
      my $toc = $self->create_toc;

      chomp $toc;

      $line =~ s/\@TOC\@/$toc/xsm;
    }

    my $title = $self->get_title;

    if ( $line =~ /\@TOC_TITLE\@/xsm ) {
      $line =~ s/\@TOC_TITLE\@/$title/xsm;
    }

    my $git_user  = $self->get_git_user  // 'anonymouse';
    my $git_email = $self->get_git_email // 'anonymouse@example.com';

    if ( $line =~ /\@GIT_(USER|EMAIL)\@/xsm ) {
      $line =~ s/\@GIT_USER\@/$git_user/xsm;

      $line =~ s/\@GIT_EMAIL\@/$git_email/xsm;
    }

    while ( $line =~ /\@DATE([(].*?[)])?\@/xsm ) {
      my $format = $1 ? $1 : '%Y-%m-%d';

      my $date = $self->format_date($format);

      $line =~ s/\@DATE([(].*?[)])?\@/$date/xsm;
    }

    if ( $line =~ /\@TOC_BACK([(].*?[)])?\@/xsm ) {
      my $back = $self->back_to_toc($1);

      $line =~ s/\@TOC_BACK([(].*?[)])?\@/$back/xsm;
    }

    $final_markdown .= $line;
  }

  close $fh;

  $self->set_markdown($final_markdown);

  return $self;

}

########################################################################
sub render_markdown {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $GITHUB_API );

  my $api_request = {
    text => $markdown,
    mode => 'markdown'
  };

  $req->content( to_json($api_request) );

  my $rsp = $ua->request($req);
  my $html;

  if ( $rsp->is_success ) {
    my $markdown_html = $rsp->content;

    my $fh = IO::Scalar->new( \$markdown_html );

    # remove junk thrown in by the API that breaks internal links
    while (<$fh>) {
      chomp;

      s/(href|id)=\"\#?user-content-/$1=\"/xsm;
      s/(href|id)=\"\#?\%60.*\%60/$1=\"#$2/xsm;

      $html .= "$_\n";
    }

    close $fh;
  }
  else {
    die $rsp->status_line;
  }

  $self->set_html($html);

  return $self;
}

########################################################################
sub format_date {
########################################################################
  my ( $self, $template ) = @_;

  require Date::Format;

  $template =~ s/[(]\"?(.*?)\"?[)]/$1/xsm;

  my $val = eval { Date::Format::time2str( $template, time ); };

  return $EVAL_ERROR ? '<undef>' : $val;
}

########################################################################
sub create_toc {
########################################################################
  my ($self) = @_;

  my $markdown = $self->get_markdown;

  my $fh = IO::Scalar->new( \$markdown );

  my $toc = $self->get_no_title ? $EMPTY : "# \@TOC_TITLE\@\n\n";

  while (<$fh>) {
    chomp;

    /^(\#+)\s+(.*?)$/xsm && do {
      my $level = $1;

      my $indent = $SPACE x ( 2 * ( length($level) - 1 ) );

      my $topic = $2;

      my $link = $topic;

      $link =~ s/^\s*(.*)\s*$/$1/xsm;

      $link =~ s/\s+/-/gxsm;  # spaces become '-'

      $link =~ s/['(),\`]//xsmg;  # known weird characters, but expect more

      $link =~ s/\///xsmg;

      $link = lc $link;

      # remove HTML entities
      $link =~ s/&\#\d+;//xsmg;

      # remove escaped entities
      $link =~ s/[{}]//xsmg;

      $toc .= sprintf "%s* [%s](#%s)\n", $indent, $topic, $link;
    };
  }

  close $fh;

  return $toc;
}

########################################################################
sub print_html {
########################################################################
  my ( $self, %options ) = @_;

  my $css   = exists $options{css}   ? $options{css}   : $self->get_css;
  my $title = exists $options{title} ? $options{title} : $self->get_infile;

  my $fh = $options{fh} // *STDOUT;

  my $title_section = $title ? "<title>$title</title>" : $EMPTY;

  my $css_section
    = $css
    ? qq{<link href="$css" rel="stylesheet" type="text/css" />}
    : $EMPTY;

  my @head = grep { $_ ? $_ : () } ( $title_section, $css_section );

  my $head_section;

  if (@head) {
    unshift @head, '<head>';
    push @head, '</head>';

    $head_section = join "\n", @head;
  }

  my $body = $self->get_html;

  print <<"END_OF_TEXT";
<html>
  $head_section
  <body>
    $body
  </body>
</html>
END_OF_TEXT

  return;
}

########################################################################
sub main {
########################################################################

  my $md = Markdown::Render->new(
    infile => shift @ARGV,
    css    => $DEFAULT_CSS
  );

  $md->finalize_markdown->render_markdown;

  $md->print_html;

  exit 0;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

Markdown::Render - Use the GitHub markdown API to render markdown as HTML

=head1 SYNOPSIS

 use Markdown::Render;

 my $md = Markdown::Render->new( infile => 'README.md');

 $md->render_markdown->print_html;

=head1 DESCRIPTION

Renders markdown as HTML using GitHub's API. Optionally adds
additional metadata to document using tags.

See L<README.md|https://github.com/rlauer6/markdown-utils/blob/master/README.md> for more details.

=head1 METHODS AND SUBROUTINES

=head2 new

 new( options )

=over 5

=item css

URL of a CSS file to add to head section of printed HTML.

=item git_user

Name of the git user that is used in the C<GIT_USER> tag.

=item git_email

Email address of the git user is used in the C<GIT_EMAIL> tag.

=item infile

Path to a file in markdow format.

=item markdown

Text of the markdown to be rendered.

=item no_title

Boolean that indicates that no title should be added to the table of contents.

default: false

=item title

Title to be used for the table of contents.

=back

=head2 finalize_markdown

Updates the markdown by interpolating the keywords. Invoking this
method will create a table of contents and replace keywords with their
values.

Invoke this method prior to invoking C<render_markdown>.

Returns the L<Markdown::Render> object.

=head2 render_markdown

Passes the markdown to GitHub's markdown rendering engine. After
invoking this method you can retrieve the processed html by invoking
C<get_html> or create a fully rendered HTML page using the C<print_html>
method.

Returns the L<Markdown::Render> object.

=head2 print_html

 print_html(options)

Outputs the fully rendered HTML page.

=over 5

=item css

URL of a CSS style sheet to include in the head section. If no CSS
file option is passed a default CSS file will b used. If a CSS element
is passed but it is undefined or empty, then no CSS will be specified
i the final document.

=item title

Title to be added in the head section of the document. If no title
option is passed the name of the file will be use as the title. If an
title option is passed but is undefined or empty, no title element
will be added to the document.

=back

=head1 AUTHOR

Rob Lauer - rclauer@gmail.com

=head1 SEE OTHER

L<GitHub Markdown API|https://docs.github.com/en/rest/markdown>

=cut
