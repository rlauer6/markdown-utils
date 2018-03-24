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

use vars qw/$VERSION/;

$VERSION = "0.1";
our %options;

use constant GITHUB_API => "https://api.github.com/markdown";

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

sub create_toc {
  my $fh = shift;

  my $toc = "# Table of Contents\n\n"
    unless exists $options{'no-title'};
  
  my $markdown_text;

  while (<$fh>) {
    $markdown_text .= "$_";
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
  
  return ($toc, $markdown_text);
}

sub version {
  require File::Basename;
	     
  my ($name,undef,undef) = File::Basename::fileparse($0, qr/\..*$/);
  
  print "$name $VERSION\n";
}

sub usage {
  print <<eot;
usage $0 options [markdown-file]

Utility to add a table of contents to your GitHub flavored markdown.

 - Add \@TOC\@ where you want to see your TOC.
 - To additionally render the HTML for the markdown, use the -r option.

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

eot
}

my @options_spec = (
		    "infile=s",
		    "outfile=s",
		    "help",
		    "render",
		    "no-title",
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

my $markdown = eval {
  if  ( $options{render} ) {
    local $/;
    render_markdown(<$fh>);  # slurp the file
  }
  else {
    my ($toc, $markdown) = create_toc($fh);
    $markdown =~s/\@TOC\@/$toc/sg;
    $markdown;
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
