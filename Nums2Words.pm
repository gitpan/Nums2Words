package Lingua::ID::Nums2Words ;

use strict ;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK) ;

require Exporter ;

@ISA = qw(Exporter) ;
@EXPORT = qw(nums2words nums2words_simple) ;
$VERSION = '0.01' ;


### package globals

use vars qw(
	$Dec_char
	$Neg_word
	$Dec_word
	$Exp_word
	$Zero_word
	%Digit_words
	%Mult_words
) ;


BEGIN {
$Dec_char  = "." ;
$Neg_word  = "negatif" ;
$Dec_word  = "koma" ;
$Exp_word  = "dikali sepuluh pangkat" ;
$Zero_word = "nol" ;

%Digit_words = (
	0 => $Zero_word, 
	1 => 'satu',
	2 => 'dua',
	3 => 'tiga',
	4 => 'empat',
	5 => 'lima',
	6 => 'enam',
	7 => 'tujuh',
	8 => 'delapan',
	9 => 'sembilan'
) ;

%Mult_words = (
	0 => '',
	1 => 'ribu',
	2 => 'juta',
	3 => 'milyar',
	4 => 'triliun'
) ;
}


### public subs
sub nums2words($) { join_it(n2w1(@_)) }
sub nums2words_simple($) { join_it(n2w5(@_)) }


### private subs


# for debugging
use vars qw($DEBUG) ;
$DEBUG = 0 ;
sub hmm___ { print "(", (caller 1)[3], ") Hmm, ", @_ if $DEBUG }


# handle scientific notation
sub n2w1($) {
	my $num = shift ;
	my @words ;

	$num =~ /^(.+)[Ee](.+)$/ and
	@words = (n2w2($1), $Exp_word, n2w2($2)) or
	@words = n2w2($num) ;

	@words 
}


# handle negative sign and decimal 
sub n2w2($) {
	my $num = shift ;
	my $is_neg ;
	my @words = () ;

        # negative 
        $num < 0 and $is_neg++ ;
       	$num =~ s/^[\s\t]*[+-]*(.*)/$1/ ;

	# decimal 
	$num =~ /^(.+)\Q$Dec_char\E(.+)$/o and 
	@words = (n2w3($1), $Dec_word, n2w5($2)) or

	$num =~ /^\Q$Dec_char\E(.+)$/o and 
	@words = ($Digit_words{0}, $Dec_word, n2w5($1)) or 

	$num =~ /^(.+)(?:\Q$Dec_char\E)?$/o and 
	@words = n2w3($1) ;

	$is_neg and
	unshift @words, $Neg_word ;

	@words
}


# handle digits before decimal
sub n2w3($) {
	my $num = shift ;
	my @words = () ;
	my $order = 0 ;
	my $t ;

	while($num =~ /^(.*?)([\d\D*]{1,3})$/) { 
		$num = $1 ;
		($t = $2) =~ s/\D//g ;
		unshift @words, $Mult_words{$order} if $t > 0 ;
		unshift @words, n2w4($t, $order) ;
		$order++ ;
	}

	@words = ($Zero_word) if not join('',@words)=~/\S/ ;
	hmm___ "for the left part of decimal i get: @words\n" ;
	@words
}


# handle clusters of thousands
sub n2w4($$) {
	my $num = shift ;
	my $order = shift ;
	my @words = () ;

	my $n1 = $num % 10 ;
	my $n2 = ($num % 100 - $n1) / 10 ;
	my $n3 = ($num - $n2*10 - $n1) / 100 ;

	$n3 == 0 && $n2 == 0 && $n1 > 0 and (
		$n1 == 1 && $order == 1 and @words = ("se") or
		@words = ($Digit_words{$n1}) ) ;

	$n3 == 1 and @words = ("seratus") or
	$n3 >  1 and @words = ($Digit_words{$n3}, "ratus") ;

	$n2 == 1 and (
		$n1 == 0 and push(@words, "sepuluh") or
		$n1 == 1 and push(@words, "sebelas") or
		push(@words, $Digit_words{$n1}, "belas") 
	) ;

	$n2 > 1 and do { 
		push @words, $Digit_words{$n2}, "puluh" ;
		push @words, $Digit_words{$n1} if $n1 > 0 ;
	} ;

	$n3 > 0 && $n2 == 0 && $n1 > 0 and
	push @words, $Digit_words{$n1} ; 

	$n3 != 0 || $n2 != 0 || $n1 != 0 and
	@words 
}


# handle digits after decimal
sub n2w5($) {
	my $num = shift ;
	my @words = () ;
	my $i ;
	my $t ;

	for( $i=0 ; $i<=length($num)-1 ; $i++ ) {
		$t = substr($num, $i, 1) ;
		exists $Digit_words{$t} and
		push @words, $Digit_words{$t} ;
	}

	@words = ($Zero_word) if not join('',@words)=~/\S/ ;
	@words
}


# join array of words, also join (se, ratus) -> seratus, etc.
sub join_it(@) {
	my $words = '' ;
	my $w ;

	while(defined( $w = shift )) {
		$words .= $w ;
		$words .= ' ' unless not length $w or $w eq 'se' or not @_ ;
	}
	$words
}


1
__END__

=head1 NAME

Lingua::ID::Nums2Words - convert number to Indonesian verbage.

=head1 SYNOPSIS

  use Lingua::ID::Nums2Words ;
  
  print nums2words(123)        ; # "seratus dua puluh tiga" 
  print nums2words_simple(123) ; # "satu dua tiga"

=head1 DESCRIPTION

B<nums2words> currently can handle real numbers in normal and scientific 
form in the order of hundreds of trillions. It also preserves formatting
in the number string (e.g, given "1.00" B<nums2words> will pronounce the 
zeros).

=head1 AUTHOR

Steven Haryanto E<lt>sh@hhh.indoglobal.comE<gt>

=head1 SEE ALSO

L<Lingua::ID::Words2Nums>

=cut
