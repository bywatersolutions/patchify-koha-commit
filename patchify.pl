#!/usr/bin/perl

use feature qw(say);

use Modern::Perl;
use File::Slurp;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

patchify.pl - Take a git patch for Koha and convert it into a debian patch that can be applied to a production server

=head1 SYNOPSIS

patchify.pl -i=/path/to/input.patch -o output.patch

patchify.pl --help

Options:
 --help        brief help message
 --man         print full help info
 --input       path to input file
 --output      patch to output file
 --output_dir  directory for output
 --commit      takes a commit id instead of an input file
 --verbose     verbose mode

=head1 OPTIONS

=over 8

=item B<--help>

Brief help

=item B<--man>

Full manual

=item B<--input>

Path to input patch

=item B<--output>

Name for output file

=item B<--output_dir

Directory for output file, defaults to /tmp if not specified

=item B<--commit>

Takes a commit id instead of an input file. This assumes you are calling the script from a Koha clone

=item B<--verbose>

Report on the lines found and updated in the patch

=back

=head1 DESCRIPTION

This script is used to convert patches from Koha into patches that can be applied directly to a packaged
koha install on a production server. This should only be done after consulting with dev and systems [insert
Spiderman speech here]

This script also attempts to scp the patch to your home directory on annon (bywater specific)

=head1 USAGE EXAMPLES

C<patchify.pl> - Brief help

C<patchify.pl> -i input.patch -o output.patch 
Process the input patch, output new patch to /tmp and scp to annon

C<patchify.pl> --commit HEAD~1 -o output/patch -d /home/kohaclone
Process the patch before head and output to kohaclone

=cut

my $input_file;
my $output_file;
my $output_dir;
my $commit_id;
my $verbose;
my $help;
my $man;

GetOptions(
    "h|help"     => \$help,
    "m|man"      => \$man,
    "i|input=s"  => \$input_file,
    "o|output=s" => \$output_file,
    "d|output_dir=s" => \$output_dir,
    "c|commit=s" => \$commit_id,
    "v|verbose"    => \$verbose,
) or pod2usage(1);

pod2usage(1) if $help;

pod2usage( -verbose => 2 ) if $man;

unless ($commit_id) {
    unless ($input_file) {
        say "-i --input <path to patch file> is required";
        pod2usage(1);
    }
    unless ($output_file) {
        say "-o --output <path to patch file> is required";
        pod2usage(1);
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
    'b/acqui/' => '/usr/share/koha/intranet/cgi-bin/acqui/',
    'b/admin/' => '/usr/share/koha/intranet/cgi-bin/admin/',
    'b/api/v1/swagger/' => '/usr/share/koha/api/v1/swagger/',
    'b/debian/scripts/koha-plack' => '/usr/sbin/koha-plack',
    'b/etc/SIPconfig.xml' => '/etc/koha/SIPconfig.xml',
    'b/installer/' => '/usr/share/koha/intranet/cgi-bin/installer/',
    'b/koha-tmpl/intranet-tmpl/' => '/usr/share/koha/intranet/htdocs/intranet-tmpl/',
    'b/koha-tmpl/opac-tmpl/' => '/usr/share/koha/opac/htdocs/opac-tmpl/',
    'b/members/memberentry.pl' => '/usr/share/koha/intranet/cgi-bin/members/memberentry.pl',
    'b/misc/' => '/usr/share/koha/bin/',
    'b/opac/' => '/usr/share/koha/opac/cgi-bin/opac/',
    'b/opac/opac-memberentry.pl' => '/usr/share/koha/opac/cgi-bin/opac/opac-memberentry.pl',
    'b/reserve/' => '/usr/share/koha/intranet/cgi-bin/reserve/',
    'b/t/'  => '/tmp/',
    'b/tools/' => '/usr/share/koha/intranet/cgi-bin/tools/',
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
