use ExtUtils::MakeMaker;

my $file = $^O =~ /MSWin32/i ? 'c2xs'
                             : 'c2xs';

open RD, '<', 'script.in' or die "Can't open script.in for reading: $!";
open OUT, '>', $file or die "Can't open $file for writing: $!";

print OUT <<"!GROK!THIS!";
$Config::Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

while(<RD>) { print OUT $_ }

close RD or die "Can't close script.in after reading: $!";
close OUT or die "Can't close $file after writing: $!";

chmod 0555, $file;


my %options =
  (
  NAME     => 'InlineX::C2XS',
  PREREQ_PM => {
                'Inline::C'  => 0.46_01,
               },
  VERSION_FROM => 'C2XS.pm',
  #PL_FILES => {c2xs.PL => 'c2xs'},
  EXE_FILES => [$file],
  clean => {FILES => '_Inline_test c2xs'},
  );

WriteMakefile(%options);

