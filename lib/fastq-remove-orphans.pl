#! /usr/bin/perl
# Victor Amin 2009

use strict;
use warnings;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

my %options;
getopts('1:2:h', \%options);

if ($options{h} || !$options{1} || !$options{2}) {Getopt::Std->version_mess(); HELP_MESSAGE(\*STDERR)}
sub HELP_MESSAGE {
  my $fh = shift;
  print $fh "\nSplit ophaned reads out of a pair of FASTQ files. Counts to STDOUT.\n";
  print $fh "\tOPTIONS:\n";
  print $fh "\t-1 [FASTQ1] [required]\n";
  print $fh "\t-2 [FASTQ2] [required]\n";
  print $fh "\nProperly paired FASTQs are outputted to paired_*, orphans to orphaned_*\n\n";
  exit;
}

open FASTQ1, "<$options{1}" or die "\nThere was a problem opening the FASTQ file: $!\n";
open FASTQ2, "<$options{2}" or die "\nThere was a problem opening the FASTQ file: $!\n";

open PAIRED1, ">paired_$options{1}" or die "\nThere was a problem opening the output file: $!\n";
open PAIRED2, ">paired_$options{2}" or die "\nThere was a problem opening the output file: $!\n";

open ORPHANED1, ">orphaned_$options{1}" or die "\nThere was a problem opening the output file: $!\n";
open ORPHANED2, ">orphaned_$options{2}" or die "\nThere was a problem opening the output file: $!\n";

my $SEQ_MODE = 1;
my $QUAL_MODE = 2;
my $mode = 1;

my $reads_1 = 0;
my $lines = 0;
my $ident;
my $sequence;
my $quality;

my %sequences_1;
my %qualities_1;
print STDERR "\nLoading first FASTQ...\n";
while (<FASTQ1>) {
    chomp;
    if (/^\@/ && $mode == $SEQ_MODE) {
    /\@([^ \/]+?)( |\/)/; # rather than substitute capture AU 16/08/2012
    # chop; this is to remove the 1 or 2 from /1 or /2 if the reads are in that format. These reads are in the format @ident 1:N:0:x or @ident 2:N:0:x AU 16/08/2012
    $ident = $1; # ident = capture AU 16/08/2012
    $reads_1++;
    } elsif (/^\+/) {
    $mode = $QUAL_MODE;
    } elsif ($mode == $SEQ_MODE) {
    $sequence .= $_;
    $lines++;
    } elsif ($mode == $QUAL_MODE) {
    $quality .= $_;
    $lines--;
    if ($lines == 0) {
      $mode = $SEQ_MODE;
      $sequences_1{$ident} = $sequence;
      $qualities_1{$ident} = $quality;
      $sequence = '';
      $quality = '';
    }
    } else {
    die "\nError reading file.\n";
    }
}

my $reads_2 = 0;

my %sequences_2;
my %qualities_2;
print STDERR "\nLoading second FASTQ...\n";
while (<FASTQ2>) {
    chomp;
    if (/^\@/ && $mode == $SEQ_MODE) {
    /\@([^ \/]+?)( |\/)/; # rather than substitute capture AU 16/08/2012
    # chop; this is to remove the 1 or 2 from /1 or /2 if the reads are in that format. These reads are in the format @ident 1:N:0:x or @ident 2:N:0:x AU 16/08/2012
    $ident = $1; # ident = capture AU 16/08/2012
    $reads_2++;
    } elsif (/^\+/) {
    $mode = $QUAL_MODE;
    } elsif ($mode == $SEQ_MODE) {
    $sequence .= $_;
    $lines++;
    } elsif ($mode == $QUAL_MODE) {
    $quality .= $_;
    $lines--;
    if ($lines == 0) {
      $mode = $SEQ_MODE;
      $sequences_2{$ident} = $sequence;
      $qualities_2{$ident} = $quality;
      $sequence = '';
      $quality = '';
    }
    } else {
    die "\nError reading file.\n";
    }
}

my $paired;
print STDERR "\nPrinting paired reads...\n";
for $ident (keys %sequences_1) {
  if (exists $sequences_2{$ident}) {
    print PAIRED1 "\@${ident} 1\n$sequences_1{$ident}\n\+${ident}1\n$qualities_1{$ident}\n";
    print PAIRED2 "\@${ident} 2\n$sequences_2{$ident}\n\+${ident}2\n$qualities_2{$ident}\n";
    delete $sequences_1{$ident};
    delete $sequences_2{$ident};
    $paired++;
  }
}

print STDERR "\nPrinting orphaned reads...\n";
my $orphaned_1;
for $ident (keys %sequences_1) {
  print ORPHANED1  "\@${ident} 1\n$sequences_1{$ident}\n\+${ident}1\n$qualities_1{$ident}\n";
  $orphaned_1++;
}

my $orphaned_2;
for $ident (keys %sequences_2) {
  print ORPHANED2  "\@${ident} 2\n$sequences_2{$ident}\n\+${ident}2\n$qualities_2{$ident}\n";
  $orphaned_2++
}

print "\nReads 1: $reads_1\nOrphans 1: $orphaned_1\nReads 2: $reads_2\nOrphaned 2: $orphaned_2\nPaired: $paired\n";