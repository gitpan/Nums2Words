###############################################################################
# Numbers to Words Package for Perl.
# Copyright (C) 1996-1998, Lester Hightower <hightowe@railwayex.com>
#				hightowe@progressive-comp.com
#				hightowe@united-railway.com
###############################################################################

package Lingua::EN::Nums2Words;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(num2word num2usdollars num2word_ordinal num2word_short_ordinal);

$VERSION = "1.11";
sub Version { $VERSION; }


# Man Page Stuff ##############################################################

=head1 NAME

Nums2Words - compute English verbage from numerical values

=head1 SYNOPSIS

=item use Nums2Words;

=item $Verbage = &num2word($Number);

=item $Verbage = &num2word_ordinal($Number);

=item $Verbage = &num2word_short_ordinal($Number);

=item $Verbage = &num2usdollars($Number);

=head1 DESCRIPTION

To the best of my knowledge, this code has the potential for
generating US English verbage representative of every real
value from negative infinity to positive infinity if the
module's private variables @Classifications and @Categories
are filled appropriately.  This module generates verbage
based on the thousands system.

See http://www.quinion.demon.co.uk/words/numbers.htm for
details of the thousands system versus millions system of
linguistically representing large numbers.

Copyright (C) 1996-1998, Lester H. Hightower, Jr.
				hightowe@united-railway.com
				hightowe@progressive-comp.com
				hightowe@railwayex.com

=head1 LICENSE

A license is hereby granted for anyone to reuse this Perl module in
its original, unaltered form for any purpose, including any commercial
software endeavor.  However, any modifications to this code or any
derivative work (including ports to other languages) must be submitted
to the original author, Lester H. Hightower Jr., before the modified
software or derivative work is used in any commercial application.
All modifications or derivative works must be submitted to the author
with 30 days of completion.  The author reserves the right to
incorporate any modifications or derivative work into future releases
of this software.

This software cannot be placed on a CD-ROM or similar media for
commercial distribution without the prior approval of the author.

=cut
###############################################################################

###############################################################################
# Private Module-global Variables #############################################
###############################################################################
# Initialization Function init_mod_vars() sets up these variables
my(@Classifications);
my(@MD);
my(@Categories);
my(%CardinalToOrdinalMapping);
my(@CardinalToShortOrdinalMapping);
###############################################################################

###############################################################################
# Public Functions ############################################################
###############################################################################
sub num2word {
  my($Number) = shift(@_);
return(&num2word_internal($Number, 0));
}

sub num2usdollars {
  my($Number) = shift(@_);
  my($Final);
  my($ShouldWeRound) = 0;
  # OK, lets do some parsing of what we were handed to be nice and
  # flexible to the users of this API
  $Number=~s/^\$//;			# Kill leading dollar sign
  # Get the decimal into hundreths
  # NOTE: LHH Replaced the sprintf() with the pattern matching
  #       and rounding code below as the sprintf() croaks on
  #       very large decimals.  06/08/1998
  # OLD_CODE: $Number=sprintf("%0.02f", $Number);
  # NEW_CODE: very ugly 27 lines of nested if statements.  Patches welcome.
  my($Int,$Dec,$UserScrewUp) = split(/\./, $Number, 3);
  my($DecPart)="00";
  if (defined($UserScrewUp) && length($UserScrewUp)) {
		warn "num2usdollars() given invalid value."; }
  if (! length($Int)) { $Int=0; }
  if (! length($Dec)) {
    $DecPart="00";
  } else {
    if ( $Dec =~ m/^([0-9])([0-9]?)([0-9]?).*$/ ) {
      if (length($3)) { $ShouldWeRound=int($3); }
      if (length($1)) { $DecPart = int($1); } else { $DecPart = "0"; }
      if (length($2)) {
        if ($ShouldWeRound > 4) {
          if (int($2) == 9) {
            if ($DecPart == 9) {
              $Int++; $DecPart='00';
            } else {
              $DecPart++; $DecPart.="0";
            }
          } else {
            $DecPart .= int($2) + 1;
          }
        } else {
          $DecPart .= int($2);
        }
      } else { $DecPart .= "0"; }
    }
  }
  $Number=$Int . '.' . $DecPart;
  # Get the num2word version
  $Final=num2word_internal($Number, 1);
  # Now whack the num2word version into a US dollar version
  my($dollar_verb)='DOLLAR';
  if (abs(int($Number)) != 1) { $dollar_verb .= 'S'; }
  if (! ($Final=~s/ AND / $dollar_verb AND /)) {
    $Final .= ' DOLLAR';
    if (abs($Number) != 1) { $Final .='S'; }
  } else {
    $Final=~s/(HUNDREDTH|TENTH)([S]?)/CENT$2/;
  }

# Return the verbage to the calling program
return($Final);
}

sub num2word_ordinal {
  my($Number) = shift(@_);
  my($Final);
  my($CardPartToConvToOrd, $ConvTo);
  # Get the num2word version
  $Final=num2word_internal($Number, 0);
  # Now whack the num2word version into a US dollar version

  if ($Final=~/ AND /) {
    if ($Final =~ m/[- ]([A-Z]+) AND/) {
      $CardPartToConvToOrd=$1;
      if (defined($CardinalToOrdinalMapping{$CardPartToConvToOrd})) {
        $ConvTo=$CardinalToOrdinalMapping{$CardPartToConvToOrd};
      } else {
        $ConvTo='';
        warn "NumToWords.pm Missing CardinalToOrdinalMapping -> $CardPartToConvToOrd";
      }
      $Final =~ s/([- ])$CardPartToConvToOrd AND/$1$ConvTo AND/;
    }
  } else {
    if ($Final =~ m/[- ]([A-Z]+)$/) {
      $CardPartToConvToOrd=$1;
      if (defined($CardinalToOrdinalMapping{$CardPartToConvToOrd})) {
        $ConvTo=$CardinalToOrdinalMapping{$CardPartToConvToOrd};
      } else {
        $ConvTo='';
        warn "NumToWords.pm Missing CardinalToOrdinalMapping -> $CardPartToConvToOrd";
      }
      $Final =~ s/([- ])$CardPartToConvToOrd$/$1$ConvTo/;
    }
  }

# Return the verbage to the calling program
return($Final);
}

sub num2word_short_ordinal {
  my($Number) = shift(@_);
  if ($Number != int($Number)) {
    warn "num2word_short_ordinal can only handle integers!\n";
    return($Number);
  }
  $Number=int($Number);
  my($least_sig_dig);
  if ($Number=~m/([0-9])$/) {
    $least_sig_dig=$1;
  } else {
    warn "num2word_short_ordinal couldn't find least significant int!\n";
    return($Number);
  }

  $Number.=$CardinalToShortOrdinalMapping[$least_sig_dig];
return($Number);
}

###############################################################################
# Private Functions ###########################################################
###############################################################################

# Init the module-global vars that we need.
# Called on module load.
&init_mod_vars;

sub num2word_internal {
  my($Number) = shift(@_);
  my($KeepTrailingZeros) = shift(@_);
  my($ClassificationIndex, %Breakdown, $Index);
  my($NegativeFlag, $Classification);
  my($Word, $Final, $DecimalVerbage) = ("", "", "");

  # Hand the number off to a function to get the verbage
  # for what appears after the decimal
  $DecimalVerbage = &HandleDecimal($Number, $KeepTrailingZeros);

  # Determine if the number is negative and if so,
  # remember that fact and then make it positive
  if (length($Number) && ($Number < 0)) {
    $NegativeFlag=1;  $Number = $Number * -1;
  }

  # Take only the integer part of the number for the
  # calculation of the integer part verbage
  # NOTE: Changed to regex 06/08/1998 by LHH because the int()
  #       was preventing the code from doing very large numbers
  #       by restricting the precision of $Number.
  # $Number = int($Number);
  if ($Number =~ /^([0-9]*)\./) {
    $Number = $1;
  }

  # Go through each of the @Classifications breaking off each
  # three number pair from right to left corresponding to
  # each of the @Classifications
  $ClassificationIndex = 0; 
  while (length($Number) > 0) {
    if (length($Number) > 2) {
      $Breakdown{$Classifications[$ClassificationIndex]} =
	  substr($Number, length($Number) - 3);
      $Number = substr($Number, 0, length($Number) - 3);
    } else {
      $Breakdown{$Classifications[$ClassificationIndex]} = $Number;
      $Number = "";
    }
    $ClassificationIndex++; 
  }

  # Go over each of the @Classifications producing the verbage
  # for each and adding each to the verbage stack ($Final)
  $Index=0;
  foreach $Classification (@Classifications) {
    # If the value of these three digits == 0 then they can be ignored
    if ( (! defined($Breakdown{$Classification})) ||
		($Breakdown{$Classification} < 1) ) { $Index++; next;}

    # Retrieves the $Word for these three digits
    $Word = &HandleThreeDigit($Breakdown{$Classification});

    # Leaves "$Classifications[0] off of HUNDREDs-TENs-ONEs numbers
    if ($Index > 0) {
      $Word .= " " . $Classification;
    }

    # Adds this $Word to the $Final and determines if it needs a comma
    if (length($Final) > 0) {
      $Final = $Word . ", " . $Final;
    } else {
      $Final = $Word;
    }
    $Index++;
  }

  # If our $Final verbage is an empty string then our original number
  # was zero, so make the verbage reflect that.
  if (length($Final) == 0) {
    $Final = "ZERO";
  }

  # If we marked the number as negative in the beginning, make the
  # verbage reflect that by prepending NEGATIVE
  if ($NegativeFlag) {
    $Final = "NEGATIVE " . $Final;
  }

  # Now append the decimal portion of the verbage calculated at the
  # beginning if there is any
  if (length($DecimalVerbage) > 0) {
    $Final .= " AND " . $DecimalVerbage;
  }

# Return the verbage to the calling program
return($Final);
}

# Helper function which handles three digits from the @Classifications
# level (THOUSANDS, MILLIONS, etc) - Deals with the HUNDREDs
sub HandleThreeDigit {
  my($Number) = shift(@_);
  my($Hundreds, $HundredVerbage, $TenVerbage, $Verbage);

  if (length($Number) > 2) {
    $Hundreds = substr($Number, 0, 1);
    $HundredVerbage = &HandleTwoDigit($Hundreds);
    if (length($HundredVerbage) > 0) {
      $HundredVerbage .= " HUNDRED";
    }
    $Number = substr($Number, 1);
  }
  $TenVerbage = &HandleTwoDigit($Number);
  if ( (defined($HundredVerbage)) && (length($HundredVerbage) > 0) ) {
    $Verbage = $HundredVerbage;
    if (length($TenVerbage)) { $Verbage .= " " . $TenVerbage; }
  } else {
    $Verbage=$TenVerbage;
  }
return($Verbage);
}

# Helper function which handles two digits (from 99 to 0)
sub HandleTwoDigit {
  my($Number) = shift(@_);
  my($Verbage, $Tens, $Ones);

  if (length($Number) < 2) {
    return($MD[$Number]);
  } else {
    if ($Number < 20) {
      return($MD[$Number]);
    } else {
      $Tens = substr($Number, 0, 1);
      $Tens = $Tens * 10;
      $Ones = substr($Number, 1, 1);
      if (length($MD[$Ones]) > 0) {
        $Verbage = $MD[$Tens] . "-" . $MD[$Ones];
      } else {
        $Verbage = $MD[$Tens];
      }
    }
  }
return($Verbage);
}

sub HandleDecimal {
  my($DecNumber) = shift(@_);
  my($KeepTrailingZeros) = shift(@_);
  my($Verbage) = "";
  my($CategoriesIndex) = 0;
  my($CategoryVerbage) = '';

  # I'm choosing to do this string-wise rather than mathematically
  # because the error in the mathematics can alter the number from
  # exactly what was sent in for high significance numbers
  # NOTE: Changed "if" to regex 06/08/1998 by LHH because the int()
  #       was preventing the code from doing very large numbers
  #       by restricting the precision of $Number.
  if ( ! ($DecNumber =~ /\./) ) {
    return('');
  } else {
    $DecNumber = substr($DecNumber, rindex($DecNumber, '.') + 1);
    # Trim off any trailing zeros...
    if (! $KeepTrailingZeros) { $DecNumber =~ s/0+$//; }
  }

  $CategoriesIndex = length($DecNumber);
  $CategoryVerbage = $Categories[$CategoriesIndex - 1];
  if (length($DecNumber) && $DecNumber == 1) {
    # if the value of what is after the decimal place is one, then
    # we need to chop the "s" off the end of the $CategoryVerbage
    # to make is singular
    chop($CategoryVerbage);
  }
  $Verbage = &num2word($DecNumber) . " " . $CategoryVerbage;
return($Verbage);
}

sub init_mod_vars {
  @Categories =		(
				"TENTHS",
				"HUNDREDTHS",
				"THOUSANDTHS",
				"TEN-THOUSANDTHS",
				"HUNDRED-THOUSANDTHS",
				"MILLIONTHS",
				"TEN-MILLIONTHS",
				"HUNDRED-MILLIONTHS",
				"BILLIONTHS",
				"TEN-BILLIONTHS",
				"HUNDRED-BILLIONTHS",
				"TRILLIONTHS",
				"QUADRILLIONTHS",
				"QUINTILLIONTHS",
				"SEXTILLIONTHS",
				"SEPTILLIONTHS",
				"OCTILLIONTHS",
				"NONILLIONTHS",
				"DECILLIONTHS",
				"UNDECILLIONTHS",
				"DUODECILLIONTHS",
				"TREDECILLIONTHS",
				"QUATTUORDECILLIONTHS",
				"QUINDECILLIONTHS",
				"SEXDECILLIONTHS",
				"SEPTEMDECILLIONTHS",
				"OCTODECILLIONTHS",
				"NOVEMDECILLIONTHS",
				"VIGINTILLIONTHS"
			);

  ###################################################

  $MD[0]  =  "";
  $MD[1]  =  "ONE";
  $MD[2]  =  "TWO";
  $MD[3]  =  "THREE";
  $MD[4]  =  "FOUR";
  $MD[5]  =  "FIVE";
  $MD[6]  =  "SIX";
  $MD[7]  =  "SEVEN";
  $MD[8]  =  "EIGHT";
  $MD[9]  =  "NINE";
  $MD[10] =  "TEN";
  $MD[11] =  "ELEVEN";
  $MD[12] =  "TWELVE";
  $MD[13] =  "THIRTEEN";
  $MD[14] =  "FOURTEEN";
  $MD[15] =  "FIFTEEN";
  $MD[16] =  "SIXTEEN";
  $MD[17] =  "SEVENTEEN";
  $MD[18] =  "EIGHTEEN";
  $MD[19] =  "NINETEEN";
  $MD[20] =  "TWENTY";
  $MD[30] =  "THIRTY";
  $MD[40] =  "FORTY";
  $MD[50] =  "FIFTY";
  $MD[60] =  "SIXTY";
  $MD[70] =  "SEVENTY";
  $MD[80] =  "EIGHTY";
  $MD[90] =  "NINETY";

  ###################################################

  @Classifications =		(
				"HUNDREDs-TENs-ONEs",
				"THOUSAND",
				"MILLION",
				"BILLION",
				"TRILLION",
				"QUADRILLION",
				"QUINTILLION",
				"SEXTILLION",
				"SEPTILLION",
				"OCTILLION",
				"NONILLION",
				"DECILLION",
				"UNDECILLION",
				"DUODECILLION",
				"TREDECILLION",
				"QUATTUORDECILLION",
				"QUINDECILLION",
				"SEXDECILLION",
				"SEPTEMDECILLION",
				"OCTODECILLION",
				"NOVEMDECILLION",
				"VIGINTILLION"
				);


  ###################################################

  $CardinalToOrdinalMapping{'ZERO'} =  "ZEROTH";
  $CardinalToOrdinalMapping{'ONE'} =  "FIRST";
  $CardinalToOrdinalMapping{'TWO'} =  "SECOND";
  $CardinalToOrdinalMapping{'THREE'} =  "THIRD";
  $CardinalToOrdinalMapping{'FOUR'} =  "FOURTH";
  $CardinalToOrdinalMapping{'FIVE'} =  "FIFTH";
  $CardinalToOrdinalMapping{'SIX'} =  "SIXTH";
  $CardinalToOrdinalMapping{'SEVEN'} =  "SEVENTH";
  $CardinalToOrdinalMapping{'EIGHT'} =  "EIGHTH";
  $CardinalToOrdinalMapping{'NINE'} =  "NINTH";
  $CardinalToOrdinalMapping{'TEN'} =  "TENTH";
  $CardinalToOrdinalMapping{'ELEVEN'} =  "ELEVENTH";
  $CardinalToOrdinalMapping{'TWELVE'} =  "TWELFTH";
  $CardinalToOrdinalMapping{'THIRTEEN'} =  "THIRTEENTH";
  $CardinalToOrdinalMapping{'FOURTEEN'} =  "FOURTEENTH";
  $CardinalToOrdinalMapping{'FIFTEEN'} =  "FIFTEENTH";
  $CardinalToOrdinalMapping{'SIXTEEN'} =  "SIXTEENTH";
  $CardinalToOrdinalMapping{'SEVENTEEN'} =  "SEVENTEENTH";
  $CardinalToOrdinalMapping{'EIGHTEEN'} =  "EIGHTEENTH";
  $CardinalToOrdinalMapping{'NINETEEN'} =  "NINETEENTH";
  $CardinalToOrdinalMapping{'TWENTY'} =  "TWENTIETH";
  $CardinalToOrdinalMapping{'THIRTY'} =  "THIRTIETH";
  $CardinalToOrdinalMapping{'FORTY'} =  "FORTIETH";
  $CardinalToOrdinalMapping{'FIFTY'} =  "FIFTIETH";
  $CardinalToOrdinalMapping{'SIXTY'} =  "SIXTIETH";
  $CardinalToOrdinalMapping{'SEVENTY'} =  "SEVENTIETH";
  $CardinalToOrdinalMapping{'EIGHTY'} =  "EIGHTIETH";
  $CardinalToOrdinalMapping{'NINETY'} =  "NINETIETH";
  $CardinalToOrdinalMapping{'HUNDRED'} =  "HUNDREDTH";
  $CardinalToOrdinalMapping{'THOUSAND'} =  "THOUSANDTH";
  $CardinalToOrdinalMapping{'MILLION'} =  "MILLIONTH";
  $CardinalToOrdinalMapping{'BILLION'} =  "BILLIONTH";
  $CardinalToOrdinalMapping{'TRILLION'} =  "TRILLIONTH";
  $CardinalToOrdinalMapping{'QUADRILLION'} =  "QUADRILLIONTH";
  $CardinalToOrdinalMapping{'QUINTILLION'} =  "QUINTILLIONTH";
  $CardinalToOrdinalMapping{'SEXTILLION'} =  "SEXTILLIONTH";
  $CardinalToOrdinalMapping{'SEPTILLION'} =  "SEPTILLIONTH";
  $CardinalToOrdinalMapping{'OCTILLION'} =  "OCTILLIONTH";
  $CardinalToOrdinalMapping{'NONILLION'} =  "NONILLIONTH";
  $CardinalToOrdinalMapping{'DECILLION'} =  "DECILLIONTH";
  $CardinalToOrdinalMapping{'TREDECILLION'} =  "TREDECILLIONTH";
  $CardinalToOrdinalMapping{'QUATTUORDECILLION'} =  "QUATTUORDECILLIONTH";
  $CardinalToOrdinalMapping{'QUINDECILLION'} =  "QUINDECILLIONTH";
  $CardinalToOrdinalMapping{'SEXDECILLION'} =  "SEXDECILLIONTH";
  $CardinalToOrdinalMapping{'SEPTEMDECILLION'} =  "SEPTEMDECILLIONTH";
  $CardinalToOrdinalMapping{'OCTODECILLION'} =  "OCTODECILLIONTH";
  $CardinalToOrdinalMapping{'NOVEMDECILLION'} =  "NOVEMDECILLIONTH";
  $CardinalToOrdinalMapping{'VIGINTILLION'} =  "VIGINTILLIONTH";

  ###################################################
  $CardinalToShortOrdinalMapping[0]='th';
  $CardinalToShortOrdinalMapping[1]='st';
  $CardinalToShortOrdinalMapping[2]='nd';
  $CardinalToShortOrdinalMapping[3]='rd';
  $CardinalToShortOrdinalMapping[4]='th';
  $CardinalToShortOrdinalMapping[5]='th';
  $CardinalToShortOrdinalMapping[6]='th';
  $CardinalToShortOrdinalMapping[7]='th';
  $CardinalToShortOrdinalMapping[8]='th';
  $CardinalToShortOrdinalMapping[9]='th';
}

1;

