use ExtUtils::MakeMaker;

my %options =
  (
  NAME     => 'InlineX::C2XS',
  PREREQ_PM => {
                'Inline::C'  => 0.46_01,
               },
  VERSION_FROM => 'C2XS.pm',
  clean => {FILES => '_Inline_test'},
  );

WriteMakefile(%options);
