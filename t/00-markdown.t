#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{.};

use Data::Dumper;
use English qw{-no_match_vars};
use Test::More;
use Bedrock::Test::Utils qw(:all);

our %TESTS = fetch_test_descriptions(*DATA);  # from Test::Utils

########################################################################

plan tests => 1 + keys %TESTS;

use_ok('Markdown::Render');

########################################################################
subtest 'new' => sub {
########################################################################
  my $md = eval {
    Markdown::Render->new(
      infile => 'README.md.in',
      engine => 'text_markdown',
    );
  };

  ok( !$EVAL_ERROR, 'new' )
    or do {
    diag( Dumper( [$EVAL_ERROR] ) );
    BAIL_OUT('could not instantiate Markdown::Render');
    };
};

########################################################################
subtest 'render_markdown' => sub {
########################################################################
  my $md = eval {
    Markdown::Render->new(
      infile => 'README.md.in',
      engine => 'text_markdown',
    );
  };

  ok( !$EVAL_ERROR, 'new(infile => file)' )
    or do {
    diag( Dumper( [$EVAL_ERROR] ) );
    BAIL_OUT('could not instantiate Markdown::Render');
    };

  ok( $md->get_markdown, 'read markdown file' );
  ok( !$md->get_html,    'no html yet' );

  isa_ok( $md->render_markdown, 'Markdown::Render' );

  ok( $md->get_html, 'render HTML' );

  ok( $md->render_markdown->get_html, 'retrieve HTML' );

  ok( $md->finalize_markdown->render_markdown->get_html,
    'finalize and render' );
};

1;

__DATA__
new => Markdown::Render->new
render_markdown => render HTML from markdown file
END_OF_PLAN  
