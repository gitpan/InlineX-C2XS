use warnings;
use strict;
use Cwd;
use Config;
use InlineX::C2XS qw(c2xs);

# We can't have this test script write its files to the cwd - because that will
# clobber the existing Makefile.PL. So ... we'll have it written to the cwd/src
# directory. The following 3 lines of code are just my attempt to ensure that
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
                  'CC' => $Config{cc},
                  'CCFLAGS' => '-DMY_DEFINE ' . $Config{ccflags},
                  'LD' => $Config{ld},
                  'LDDLFLAGS' => $Config{lddlflags},
                  'MAKE' =>  $Config{make},
                  'MYEXTLIB' => 'MANIFEST', # this test needs *only* that the file exists
                  'OPTIMIZE' => '-g',
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

$ok = 0;

@rd1 = <RD1>;

# Not sure how best to check that the generated Makefile.PL is ok.
# In the meantime we have the following crappy checks. If it passes
# these tests, it's probably ok ... otherwise it may not be.

my ($line1, $line2, $line3, $line4, $line5, $line6, $line7, $line8, $line9, $line10, $line11,
    $line12, $line13, $line14, $line15, $line16, $line17, $line18) = 
   (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

for(@rd1) {
   if ($_ =~ /use ExtUtils::MakeMaker;/) {$line1 = 1}
   if ($_ =~ /my %options = %{/) {$line2 = 1}
   if ($_ =~ /INC/ && $_ =~ / \-Isrc/) {$line3 = 1}
   if ($_ =~ /NAME/ && $_ =~ /test/) {$line4 = 1}
   if ($_ =~ /LIBS/) {$line5 = 1}
   if ($_ =~ /\-L\/anywhere \-lbogus/) {$line6 = 1}
   if ($_ =~ /TYPEMAPS/) {$line7 = 1}
   if ($_ =~ /simple_typemap\.txt/) {$line8 = 1}
   if ($_ =~ /VERSION/ && $_ =~ /0.42/) {$line9 = 1}
   if ($_ =~ /WriteMakefile\(%options\);/) {$line10 = 1}
   if ($_ =~ /sub MY::makefile { '' }/) {$line11 = 1}
   if ($_ =~ /CC/ && $_ =~ /\Q$Config{cc}\E/) {$line12 = 1}
   if ($_ =~ /CCFLAGS/ && $_ =~ /\s\-DMY_DEFINE/) {$line13 = 1}
   if ($_ =~ /LD/ && $_ =~ /\Q$Config{ld}\E/) {$line14 = 1}
   if ($_ =~ /LDDLFLAGS/) {$line15 = 1}
   if ($_ =~ /MAKE/ && $_ =~ /\Q$Config{make}\E/) {$line16 = 1}
   if ($_ =~ /MYEXTLIB/ && $_ =~ /MANIFEST/) {$line17 = 1}
   if ($_ =~ /OPTIMIZE/ && $_ =~ /\-g/) {$line18 = 1}
}

if($line1 && $line2 && $line3 && $line4 && $line5 && $line6 && $line7 && $line8 && $line9 && $line10 && $line11
   && $line12 && $line13 && $line14 && $line15 && $line16 && $line17 && $line18) {$ok = 1}

if(!$ok) {
  print "not ok 3 - src/Makefile.PL not properly created ", $line1, $line2, $line3, $line4, $line5, $line6, $line7, $line8, $line9, $line10, $line11,
         $line12, $line13, $line14, $line15, $line16, $line17, $line18, "\n";
  close(RD1) or print "Unable to close src/Makefile.PL after reading: $!\n";
  exit;
}

close(RD1) or print "Unable to close src/Makefile.PL after reading: $!\n";
if(!unlink('src/Makefile.PL')) { print "Couldn't unlink src/Makefile.PL\n"}

print "ok 3\n";
