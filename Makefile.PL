use ExtUtils::MakeMaker;

my %options =
  (
  NAME     => 'InlineX::C2XS',
  PREREQ_PM => {
                'Inline::C'  => 0.44,
               },
  VERSION_FROM => 'C2XS.pm',
  );

WriteMakefile(%options);