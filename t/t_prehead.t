use warnings;
use strict;
use InlineX::C2XS qw(c2xs);

print "1..4\n";

my $xs = './testing/test.xs';
my $seen = 0;

my %config_opts = (
                  'AUTOWRAP' => 1,
                  'PRE_HEAD' => "#define MUMBO_JUMBO 5432\n",
                  'AUTO_INCLUDE' => '#include <simple.h>' . "\n" .'#include "src/extra_simple.h"',
                  'TYPEMAPS' => 'src/simple_typemap.txt',
                  'INC' => '-Isrc',
                  );

c2xs('test', 'test', './testing', \%config_opts);

open RD, '<', $xs or die "Can't open $xs for reading: $!";

while(<RD>) {
  if($_ =~ /EXTERN/) { $seen++ }
  if($_ =~ /MUMBO_JUMBO/) {
    if($seen) {
      warn "\$seen: $seen\n";
      print "not ok 1\n";
      }
    else {print "ok 1\n"}
  }  
} # while

if($seen == 1) {print "ok 2\n"}
else {
  warn "\$seen: $seen\n";
  print "not ok 2\n";
}

close RD or die "Can't close $xs after reading: $!";

$xs = './testing2/test.xs';
$seen = 0;
$config_opts{PRE_HEAD} = 't/prehead.in';

c2xs('test', 'test', './testing2', \%config_opts);

open RD2, '<', $xs or die "Can't open $xs for reading: $!";

while(<RD2>) {
  if($_ =~ /EXTERN/) { $seen++ }
  if($_ =~ /SOMETHING_ELSE/) {
    if($seen) {
      warn "\$seen: $seen\n";
      print "not ok 3\n";
      }
    else {print "ok 3\n"}
  }  
} # while

if($seen == 1) {print "ok 4\n"}
else {
  warn "\$seen: $seen\n";
  print "not ok 4\n";
}

close RD2 or die "Can't close $xs after reading: $!";

unlink('./testing/INLINE.h', './testing/test.xs', './testing2/INLINE.h', './testing2/test.xs');