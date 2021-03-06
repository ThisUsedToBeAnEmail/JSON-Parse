# This tests the EXPORTS section of the pod documentation lists all
# the exported functions, and that all the listed functions are
# exported.

use warnings;
use strict;
use JSON::Parse;
use Pod::Select;
use FindBin '$Bin';
use Test::More;

# Find out what is really exported from the module by poking our nose
# in where it's not supposed to go.

my @exports = @JSON::Parse::EXPORT_OK;
my %reallyexports;
@reallyexports{@exports} = @exports;

# The Master Pod File:

my $pod = "$Bin/../lib/JSON/Parse.pod";
die "no $pod found" if ! -f $pod;

# Pod text goes in here.

my $exports_pod;

# Deal with pod select restriction to file handles by opening string
# as file handle.

open my $out, ">", \$exports_pod or die $!;

# See "perldoc Pod::Select".

podselect ({
    -output => $out,
    -sections => ['EXPORTS'],
}, $pod);

# Check we have listed everything in the pod.

my %exports;
while ($exports_pod =~ m!L</(\w*)>!g) {
    $exports{$1} = 1;
}
for my $function (@exports) {
    ok ($exports{$function}, "listed $function");
}

# Check everything listed in the pod really is exported.

for my $function (keys %exports) {
    ok ($reallyexports{$function}, "really does export $function");
}

# Everything is dandy.

done_testing ();
exit;
