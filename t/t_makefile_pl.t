use warnings;
use strict;
use Cwd;
use InlineX::C2XS qw(c2xs);

# We can't have this test script write its files to the cwd - because that will
# clobber the existing Makefile.PL. So ... we'll have it written to the cwd/src
# directory. The following 3 lines are code are just my attempt to ensure that
# the Makefile.PL does NOT get written to the cwd.  
my $cwd = getcwd;
my $build_dir = "${cwd}/src";
die "Can't run the t_makefile_pl.t test script" unless -d $build_dir;


print "1..3\n";

my %config_opts = (
                  'AUTOWRAP' => 1,
                  'AUTO_INCLUDE' => '#include <simple.h>' . "\n" .'#include "src/extra_simple.h"',
                  'TYPEMAPS' => ['src/simple_typemap.txt'],
                  'INC' => '-Isrc',
                  'WRITE_MAKEFILE_PL' => 1,
                  'LIBS' => ['-L/anywhere -lbogus'],
                  'VERSION' => 0.42,
                  'BUILD_NOISY' => 0,
                  );

c2xs('test', 'test', $build_dir, \%config_opts);

if(!rename('src/test.xs', 'src/test.txt')) {
  print "not ok 1 - couldn't rename src/test.xs\n";
  exit;
}

my $ok = 1;

if(!open(RD1, "src/test.txt")) {
  print "not ok 1 - unable to open src/test.txt for reading: $!\n";
  exit;
}

if(!open(RD2, "expected_autowrap.txt")) {
  print "not ok 1 - unable to open expected_autowrap.txt for reading: $!\n";
  exit;
}

my @rd1 = <RD1>;
my @rd2 = <RD2>;

if(scalar(@rd1) != scalar(@rd2)) {
  print "not ok 1 - src/test.txt does not have the expected number of lines\n";
  close(RD1) or print "Unable to close src/test.txt after reading: $!\n";
  close(RD2) or print "Unable to close expected_autowrap.txt after reading: $!\n";
  exit;
}

for(my $i = 0; $i < scalar(@rd1); $i++) {
   # Try to take care of platform-specific issues with line endings.
   $rd1[$i] =~ s/\n//g;
   $rd2[$i] =~ s/\n//g;
   $rd1[$i] =~ s/\r//g;
   $rd2[$i] =~ s/\r//g;

   if($rd1[$i] ne $rd2[$i]) {
     print $i, "\n", $rd1[$i], "*\n", $rd2[$i], "*\n";
     $ok = 0;
     last;
   }
}

if(!$ok) {
  print "not ok 1 - src/test.txt does not match expected_autowrap.txt\n";
  close(RD1) or print "Unable to close src/test.txt after reading: $!\n";
  close(RD2) or print "Unable to close expected_autowrap.txt after reading: $!\n";
  exit;
}

print "ok 1\n";

close(RD1) or print "Unable to close src/test.txt after reading: $!\n";
close(RD2) or print "Unable to close expected_autowrap.txt after reading: $!\n";
if(!unlink('src/test.txt')) { print "Couldn't unlink src/test.txt\n"}

$ok = 1;

###########################################################################

if(!open(RD1, "src/INLINE.h")) {
  print "not ok 2 - unable to open src/INLINE.h for reading: $!\n";
  exit;
}

if(!open(RD2, "expected.h")) {
  print "not ok 2 - unable to open expected.h for reading: $!\n";
  exit;
}

@rd1 = <RD1>;
@rd2 = <RD2>;

if(scalar(@rd1) != scalar(@rd2)) {
  print "not ok 2 - src/INLINE.h does not have the expected number of lines\n";
  close(RD1) or print "Unable to close src/INLINE.h after reading: $!\n";
  close(RD2) or print "Unable to close expected.h after reading: $!\n";
  exit;
}

for(my $i = 0; $i < scalar(@rd1); $i++) {
   # Try to take care of platform-specific issues with line endings.
   $rd1[$i] =~ s/\n//g;
   $rd2[$i] =~ s/\n//g;
   $rd1[$i] =~ s/\r//g;
   $rd2[$i] =~ s/\r//g;

   if($rd1[$i] ne $rd2[$i]) {
     $ok = 0;
     last;
   }
}

if(!$ok) {
  print "not ok 2 - src/INLINE.h does not match expected.h\n";
  close(RD1) or print "Unable to close src/INLINE.h after reading: $!\n";
  close(RD2) or print "Unable to close expected.h after reading: $!\n";
  exit;
}

close(RD1) or print "Unable to close src/INLINE.h after reading: $!\n";
close(RD2) or print "Unable to close expected.h after reading: $!\n";
if(!unlink('src/INLINE.h')) { print "Couldn't unlink src/INLINE.h\n"}

print "ok 2\n";


###########################################################################

if(!open(RD1, "src/Makefile.PL")) {
  print "not ok 3 - unable to open src/Makefile.PL for reading: $!\n";
  exit;
}

if(!open(RD2, "expected_makefile_pl.txt")) {
  print "not ok 3 - unable to open expected_makefile_pl.txt for reading: $!\n";
  exit;
}

@rd1 = <RD1>;
@rd2 = <RD2>;

if(scalar(@rd1) != scalar(@rd2)) {
  print "not ok 3 - src/Makefile.PL does not have the expected number of lines\n";
  close(RD1) or print "Unable to close src/Makefile.PL after reading: $!\n";
  close(RD2) or print "Unable to close expected_makefile_pl.txt after reading: $!\n";
  exit;
}

my $ignore_next = 0;

for(my $i = 0; $i < scalar(@rd1); $i++) {

   if($ignore_next) {
      $ignore_next = 0;
      warn "Ignoring machine-dependent path. (This warning should arise only once.)";
      next;
   }

   # Try to take care of platform-specific issues with line endings.
   $rd1[$i] =~ s/\n//g;
   $rd2[$i] =~ s/\n//g;
   $rd1[$i] =~ s/\r//g;
   $rd2[$i] =~ s/\r//g;

   # The line after "'TYPEMAPS' => [" contains a machine-dependent path.
   # Assume it's ok, and ignore it ... until I work out how Inline::C
   # sets the value. 
   if($rd1[$i] =~ /TYPEMAPS/) {$ignore_next = 1}

   if($rd1[$i] =~ /INC/) {
     $cwd =~ s/\\/\//g;
     $ok = 0 unless $rd2[$i] =~ /INC/;
     $ok = 0 unless $rd1[$i] =~ /\s-Isrc'/;
     $ok = 0 unless $rd1[$i] =~ /'\-I\Q$cwd\E\/t\s/;
     last unless $ok;
   }

   else {
     if($rd1[$i] ne $rd2[$i]) {
       $ok = 0;
       print "\n$rd1[$i]\n$rd2[$i]\n" unless $ok;
       last;
     }
   }
}

if(!$ok) {
  print "not ok 3 - src/Makefile.PL does not match expected_makefile_pl.txt\n";
  close(RD1) or print "Unable to close src/Makefile.PL after reading: $!\n";
  close(RD2) or print "Unable to close expected_makefile_pl.txt after reading: $!\n";
  exit;
}

close(RD1) or print "Unable to close src/Makefile.PL after reading: $!\n";
close(RD2) or print "Unable to close expected_makefile_pl.txt after reading: $!\n";
if(!unlink('src/Makefile.PL')) { print "Couldn't unlink src/Makefile.PL\n"}

print "ok 3\n";
