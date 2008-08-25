use ExtUtils::MakeMaker;
my %options = %{       
{
  'TYPEMAPS' => [
    'C:\\perl58_M\\lib\\ExtUtils\\typemap'
  ],
  'NAME' => 'MyMod',
  'INC' => '-IC:/_32/working/inlinex-c2xs/InlineX-C2XS-0.13/demos/autowrap',
  'VERSION' => '0.01'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
