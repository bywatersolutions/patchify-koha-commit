#!/usr/bin/perl

use feature qw(say);

use Modern::Perl;
use File::Slurp;
use Getopt::Long;

my $input_file;
my $output_file;
my $output_dir;
my $commit_id;
my $verbose;

GetOptions(
    "i|input=s"  => \$input_file,
    "o|output=s" => \$output_file,
    "d|output_dir=s" => \$output_dir,
    "c|commit=s" => \$commit_id,
    "verbose"    => \$verbose,
) or die("Error in command line arguments\n");

unless ($commit_id) {
    unless ($input_file) {
        say "-i --input <path to patch file> is required";
        exit 1;
    }
    unless ($output_file) {
        say "-o --output <path to patch file> is required";
        exit 1;
    }
}

if ($commit_id) {
    unless ($output_dir) {
        $output_dir = "/tmp";
    }
    my $cmd;
    $cmd = `git format-patch -N -o $output_dir -1 $commit_id`;

    $input_file = $cmd;
    chomp $input_file;
    $output_file = $input_file;
}

my @lines = read_file($input_file);

my $mapping = {
    'b/C4/' => '/usr/share/koha/lib/C4/',
    'b/Koha/' => '/usr/share/koha/lib/Koha/',
    'b/installer/' => '/usr/share/koha/intranet/cgi-bin/installer/',
    'b/opac/' => '/usr/share/koha/opac/cgi-bin/opac/',
    'b/misc/' => '/usr/share/koha/bin/',
    'b/tools/' => '/usr/share/koha/intranet/cgi-bin/tools/',
    'b/koha-tmpl/intranet-tmpl/' => '/usr/share/koha/intranet/htdocs/intranet-tmpl/',
    'b/koha-tmpl/opac-tmpl/' => '/usr/share/koha/opac/htdocs/opac-tmpl/',
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

my $send = `scp $output_file annon:~/`;

