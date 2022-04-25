#!/usr/bin/perl -w
# thanks to source: https://gist.github.com/itsvenu/e0233043ba77c5ce48aa
my $columns = 60;


my $progname = $0;
$progname =~ s/^.*?([^\/]+)$/$1/;

my $usage = "Usage: $progname [<Stockholm file(s)>]\n";
$usage .=   "             [-h] print this help message\n";
$usage .=   "             [-g] write gapped FASTA output\n";
$usage .=   "             [-s] sort sequences by name\n";
$usage .=   "      [-c <cols>] number of columns for FASTA output (default is $columns)\n";
# parse cmd-line opts
my @argv;
while (@ARGV) {
    my $arg = shift;
    if ($arg eq "-h") {
	die $usage;
    } elsif ($arg eq "-g") {
	$gapped = 1;
    } elsif ($arg eq "-s"){
	$sorted = 1;
    } elsif ($arg eq "-c") {
	defined ($columns = shift) or die $usage;
    } else {
	push @argv, $arg;
    }
}
@ARGV = @argv;

my @seqorder = ();

my %seq;
while (<>) {
    next unless /\S/;
    next if /^\s*\#/;
    if (/^\s*\/\//) { printseq() }
    else {
	chomp;
	my ($name, $seq) = split;
	push @seqorder, $name unless exists $seq{$name};
	$seq{$name} .= $seq;
    }
}
printseq();

sub printseq {

    @seqorder = sort @seqorder if $sorted;

    foreach $key (@seqorder) {
	print ">$key\n";
	for (my $i = 0; $i < length $seq{$key}; $i += $columns){
	    print substr($seq{$key}, $i, $columns), "\n";
	}
    }

    %seq = ();
    @seqorder = ();
}
