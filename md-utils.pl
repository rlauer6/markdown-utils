#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Slurp;
use Getopt::Long;
use HTTP::Request;
use IO::Scalar;
use JSON;
use LWP::UserAgent;

use constant GITHUB_API => "https://api.github.com/markdown";

use vars qw/$VERSION/;

$VERSION = "0.2";

our %options;

our %GLOBALS = (
		TOC_TITLE => "Table of Contents"
	       );

eval {
  $GLOBALS{GIT_USER} = `git config --global user.name`;
  chomp $GLOBALS{GIT_USER};
  
  $GLOBALS{GIT_EMAIL} = `git config --global user.email`;
  chomp $GLOBALS{GIT_EMAIL};
};

our %FUNCTIONS = (
		  TOC   => \&_create_toc,
		  DATE  => \&_date_format,
		 );
		  
sub finalize_markdown {
  my %options = @_;

  my $markdown = $options{markdown};
  
  my $fh = IO::Scalar->new(\$markdown);
  my $final_markdown;
  
  while (my $line = <$fh>) {

    if ( $line =~/\@TOC\@/ ) {
      my $toc = $FUNCTIONS{TOC}->($options{markdown});
      chomp $toc;
      $line =~s/\@TOC\@/$toc/;
    }

    if ( $line =~/\@TOC_TITLE\@/ ) {
      $line =~s/\@TOC_TITLE\@/$GLOBALS{TOC_TITLE}/s;
    }

    if ( $line =~/\@GIT_(USER|EMAIL)\@/ ) {
      $line =~s/\@GIT_USER\@/$GLOBALS{GIT_USER}/;
      $line =~s/\@GIT_EMAIL\@/$GLOBALS{GIT_EMAIL}/;
    }

    while ( $line =~/\@DATE(\(.*?\))?\@/ ) {
      my $date = $FUNCTIONS{DATE}->($1);
      $line =~s/\@DATE(\(.*?\))?\@/$date/;
    }
    
    $final_markdown .= $line;
  }
  
  close $fh;
  
  $final_markdown;
}

sub render_markdown {
  my $markdown = shift;
  
  my $ua = new LWP::UserAgent;
  my $req = new HTTP::Request('POST', GITHUB_API);
  
  my $api_request = {
		    text => $markdown,
		    mode => "markdown"
		   };
  
  $req->content(to_json($api_request));
	      
  my $rsp = $ua->request($req);
  my $html;

  if ( $rsp->is_success ) {
    my $markdown_html = $rsp->content;
    
    my $fh = IO::Scalar->new(\$markdown_html);
    
    # remove junk thrown in by the API that breaks internal links
    while (<$fh>) {
      chomp;
      s/(href|id)=\"\#?user-content-/$1=\"/;
      $html .= "$_\n";
    }
    
    close $fh;
  }
  else {
    die $rsp->status_line;
  }
  
  return $html;
}

sub _date_format {
  my $template = shift;

  require Date::Format;
  
  $template =~s/\(\"?(.*?)\"?\)/$1/;

  my $val = eval {
    Date::Format::time2str($template, time);
  };
  
  return $@ ? "<undef>" : $val;
}

sub _create_toc {
  my $markdown = shift;
  
  my $fh = IO::Scalar->new(\$markdown);
  
  my $toc = "# \@TOC_TITLE\@\n\n"
    unless exists $options{'no-title'};
  
  while (<$fh>) {
    chomp;

    /^(#+)\s+(.*?)$/ && do {
      my $level = $1;
      my $indent = " " x (2*(length($level)-1));
      my $topic = $2;
      my $link = $topic;
      $link =~s/^\s*(.*)\s*$/$1/;
      $link =~s/\s+/-/g; # spaces become '-'
      $link =~s/[']//g; # known weird characters, but expect more
      $link=lc($link);
      
      $toc .= sprintf("%s* [%s](#%s)\n", $indent, $topic, $link);
    };
  }
  
  close $fh;
  
  return $toc;
}

sub version {
  require File::Basename;
	     
  my ($name,undef,undef) = File::Basename::fileparse($0, qr/\..*$/);
  
  print "$name $VERSION\n";
}

sub usage {
  print <<eot;
usage $0 options [markdown-file]

Utility to add a table of contents and other goodies to your GitHub
flavored markdown.

 - Add \@TOC\@ where you want to see your TOC.
 - Add \@DATE(format-str)\@ where you want to see a formatted date
 - Add \@GIT_USER\@ where you want to see your git user name
 - Add \@GIT_EMAIL\@ where you want to see your git email address
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
-v, --version   version
-n, --no-title  do not print a title for the TOC
-t, --title     string to use for a custom title, default: "Table of Contents"

eot
}

my @options_spec = (
		    "infile=s",
		    "outfile=s",
		    "help",
		    "render",
		    "no-title",
		    "title=s",
		    "debug",
		    "version"
		   );

GetOptions(\%options, @options_spec) or
  die "could not parse options";

if ( exists $options{help} ) {
  usage;
  exit 0;
}

if ( exists $options{version} ) {
  version;
  exit 0;
}

if ( exists $options{title} ) {
  $GLOBALS{TOC_TITLE} = $options{title};
}
  
my $fh;

if ( exists $options{infile} ) {
  open ($fh, "<$options{infile}") or die "could not open " . $options{infile} . "\n";
}
elsif ( @ARGV ) {
  open ($fh, "<$ARGV[0]") or die "could not open " . $ARGV[0] . "\n";
}
else {
    $fh = *STDIN;
}

my $raw_markdown = eval {
  local $/;
  <$fh>;
};

my $markdown = eval {
  if  ( $options{render} ) {
    render_markdown($raw_markdown);  # slurp the file
  }
  else {
    finalize_markdown(markdown => $raw_markdown, %GLOBALS);
  }
};

die "error: $@\n"
  if $@;

my $ofh = *STDOUT;

if ( exists $options{outfile} ) {
  open ($ofh, ">$options{outfile}") or die "could not open output file\n";
}

print $ofh $markdown;

close $ofh;

exit(0);
