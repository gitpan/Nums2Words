#!/usr/local/bin/perl
#
# This command makes a nice printout:
#	num2word.test.pl |enscript -r -f Courier@6
#

use strict;
use Lingua::EN::Nums2Words;


my($a);
my(@foo);
my($num);
for $a (0..5) {
  $num=rand(5000);
  my($dec)=int(rand(6));
  my($fmt)="%0." . $dec . "f";
  $num=sprintf("$fmt", $num);
  if (int(rand(2))) { $num=$num * -1; }
  push(@foo, $num);
}

# And for good measure, this was suggested by:
# http://www.rosat.mpe-garching.mpg.de/mailing-lists/modules/ \
#		1998-06/msg00013.html
push(@foo, "476206098657263575912.476206098657263575912");

for $num (@foo) {
  printf ("%15s: %-s\n", $num, &num2word($num));
  printf ("%15s: %-s\n", $num, &num2word_ordinal($num));
  printf ("%15s: %-s\n", $num, &num2usdollars($num));
}

