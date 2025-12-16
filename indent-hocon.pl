#!/usr/bin/env perl
use open qw(:utf8 :std);
use warnings qw(FATAL utf8);
my $indent = 0;
my $in_block_quote = 0;
my $comment_prefix = '';
my $space_per_index = $ENV{INDENTATION} || 2;

$extension = '.orig';
LINE: while (<>) {
  if ($ARGV ne $old_argv) {
    $indent = 0;
    $in_block_quote = 0;
    $comment_prefix = '';
    if ($extension !~ /\*/) {
      $backup = $ARGV . $extension;
    }
    else {
      ($backup = $extension) =~ s/\*/$ARGV/g;
    }
    rename($ARGV, $backup);
    open(ARGV_OUT, ">$ARGV");
    select(ARGV_OUT);
    $old_argv = $ARGV;
  }

  $line=$_;
  s/\x{00a0}/ /g;
  s/(?<!")"([^"])+"/<>/; # ignore quoted strings
  s/\$\{.*?\}/<>/; # ignore variable substitutions
  if (s!(.*)(?://|#).*?!$1!) {
    # ignore comments
    if ($comment_prefix eq '') {
      my $new_comment_prefix = $1;
      $comment_prefix = $new_comment_prefix if $new_comment_prefix =~ /^\s*$/;
    }
  } else {
    $comment_prefix = '';
  }
  if (! $in_block_quote || /"""/) {
    while (s/^(.*?)"""(.*)$//) {
      if ($in_block_quote) {
        $_ = $2;
      } else {
        $_ = $1;
      }
      $in_block_quote ^= 1;
    };
    s/^(\s*)\x{00a0}/$1 /g;
    # adjust current indentation
    $indent-- while (s/^\s*[\]}]//);
    my $indentation = " "x($indent*$space_per_index);
    if ($line =~ /^\s*$/) {
      $line = "\n";
    } else {
      if ($line =~ m!^\s*(?://|#)!) {
        $line =~ s/^\s*/$comment_prefix/;
      } else {
        $line =~ s/^\s*/$indentation/;
      }
    }
    # adjust indentation
    $indent++ while s/[\[{]//;
    $indent-- while s/[\]}]//;

    $line =~ s/^(\s*)\x{00a0}/$1 /g;
    $line =~ s/ +($)//;
  }
  $_ = $line;
}
continue {
  print; # this prints to original filename
}
select(STDOUT);

