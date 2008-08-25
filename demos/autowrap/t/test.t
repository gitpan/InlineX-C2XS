use warnings;
use strict;
use MyMod;

print "1..1\n";

my $erf = MyMod::erf(2);

if($erf > 0.99532226 && $erf < 0.99532227) {print "ok 1\n"}
else {print "not ok 1\n"};
