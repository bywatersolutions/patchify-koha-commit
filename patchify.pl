#!/usr/bin/perl

use feature qw(say);

use Modern::Perl;
use File::Slurp;
use Getopt::Long;

my $input_file;
my $output_file;
my $verbose;

GetOptions(
    "i|input=s"  => \$input_file,
    "o|output=s" => \$output_file,
    "verbose"    => \$verbose,
) or die("Error in command line arguments\n");

unless ($input_file) {
    say "-i --input <path to patch file> is required";
    exit 1;
}
unless ($output_file) {
    say "-o --output <path to patch file> is required";
    exit 1;
}

my @lines = read_file($input_file);

my $mapping = {
    'b/C4/' => '/usr/share/koha/lib/C4/',
    'b/Koha/' => '/usr/share/koha/lib/Koha/',
    'b/t/'  => '/tmp/',
};

my $b_line = qr/^\+\+\+ b\//;

foreach my $line (@lines) {
    if ( $line =~ m/$b_line/ ) {    # match on
        print "FOUND LINE: $line" if $verbose;

        foreach my $from ( keys %$mapping ) {
            my $to = $mapping->{$from};
            $line =~ s/$from/$to/;
        }

        print "NO MAPPING FOUND FOR $line" if $line =~ m/$b_line/;
    }
}

write_file( $output_file, @lines );
