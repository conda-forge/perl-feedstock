use strict;
use warnings;

my $vers = $ENV{PKG_VERSION}
    // die "PKG_VERSION empty, can't determine version string";
my ($major, $minor) = split /\./, $vers;
die "No minor version part found"
    if (! length $minor);

my ($fn_in, $fn_out) = @ARGV;

die "Library $fn_in not found"
    if (! -e $fn_in);

# we reserved 256 bytes for each path during compilation
my $placeholder = 'ph' . '_' x (256*6-4) . 'ph';
# in Windows, the paths are semicolon-delimited
my $replacement = join ';',
    map { "$ENV{PREFIX}/lib/perl5/$_" }
    map { $_, "$major.$minor/$_" }
    qw/
    	core_perl
	site_perl
	vendor_perl
    /;
die "Replacement paths too long, must be <= 256 characters"
    if (length $placeholder < length $replacement);

# the replacement string needs to be the same number of bytes as the original.
# At first null padding was tried, but that led to errors in later use
# ("Invalid null character in @INC" or the like). However, the string
# itself is a semicolon-delimited list of paths, so I tried padding with
# extra semicolons. This seems to work, as the trailing semicolons are
# simply ignored.

my $padding = length($placeholder) - length($replacement);
$replacement .= ';' x $padding;
my $l_ph = length $placeholder;
my $l_re = length $replacement;
die "Replacement length still unequal after padding"
    if (length $placeholder != length $replacement);

# read in original DLL in binary mode
open my $in, '<:raw', $fn_in
    or die "Error opening in: $!";
local $/ = undef;
my $dll = <$in>;
close $in;

my $len_orig = length $dll;

# perform actual substitution and ensure that exactly one substitution
# was made and the sizes still match

my $n_replacements
    = ($dll =~ s/$placeholder/$replacement/g);
die "No placeholders found for replacement!"
    if ($n_replacements < 1);
die "Too many placeholders found for replacement!"
    if ($n_replacements > 1);
die "Altered DLL size different than original"
    if (length $dll != $len_orig);

# if everything still looks okay, overwrite original file
open my $out, '>:raw', $fn_out
    or die "Error opening $fn_out: $!";
print {$out} $dll;
close $out;
