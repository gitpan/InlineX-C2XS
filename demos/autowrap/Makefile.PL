use ExtUtils::MakeMaker;
my %options = %{       
{
  'TYPEMAPS' => [
    'D:\\perl58_M\\5.8.8\\lib\\ExtUtils\\typemap'
  ],
  'NAME' => 'MyMod',
  'INC' => '-ID:/Inline-C2XS/InlineX-C2XS-0.08/demos/autowrap',
  'VERSION' => '0.01'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
