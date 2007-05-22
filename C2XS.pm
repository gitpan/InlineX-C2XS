package InlineX::C2XS;
use warnings;
use strict;
use Carp;
use Config;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(c2xs);

our $VERSION = 0.11;

sub c2xs {
    eval {require "Inline/C.pm"};
    if($@ || $Inline::C::VERSION < 0.44) {die "Need a functioning Inline::C (version 0.44 or later). $@"}
    my $module = shift;
    my $pkg = shift;

    # Set the defaults for $build_dir and $config_options.
    # (These will be overwritten by any supplied arguments.)
    my ($build_dir, $config_options) = (
       '.', 
       {
       'AUTOWRAP' => 0,
       'AUTO_INCLUDE' => '',
       'TYPEMAPS' => [],
       'LIBS' => [],
       'INC' => '',
       'VERSION' => 0,
       'WRITE_MAKEFILE_PL' => 0,
       }
                                        );
    
    if(@_) {
      if(ref($_[0]) eq "HASH") {
        $config_options = shift; 
      }
      else {$build_dir = shift}
    }

    if(@_) {
      if(ref($_[0]) ne "HASH") {die "Fourth arg to c2xs() needs to be a hash containing config options ... but it's not !!\n"}  
      $config_options = shift;
    }

    unless(-d $build_dir) {
       die "$build_dir is not a valid directory";
    }
    my $modfname = (split /::/, $module)[-1];
    my $need_inline_h = $config_options->{AUTOWRAP} ? 1 : 0;
    my $code = '';
    my $o;

    open(RD, "<", "src/$modfname.c") or die "Can't open src/${modfname}.c for reading: $!";
    while(<RD>) { 
         $code .= $_;
         if($_ =~ /inline_stack_vars/i) {$need_inline_h = 1}
    }
    close(RD) or die "Can't close src/$modfname.c after reading: $!";

    ## Initialise $o.
    ## Many of these keys may not be needed for the purpose of this
    ## specific exercise - but they shouldn't do any harm, so I'll
    ## leave them in, just in case they're ever needed.
    $o->{CONFIG}{BUILD_TIMERS} = 0;
    $o->{CONFIG}{PRINT_INFO} = 0;
    $o->{CONFIG}{USING} = [];
    $o->{CONFIG}{WARNINGS} = 1;
    $o->{CONFIG}{PRINT_VERSION} = 0;
    $o->{CONFIG}{CLEAN_BUILD_AREA} = 0;
    $o->{CONFIG}{GLOBAL_LOAD} = 0;
    $o->{CONFIG}{DIRECTORY} = '';
    $o->{CONFIG}{SAFEMODE} = -1;
    $o->{CONFIG}{CLEAN_AFTER_BUILD} = 1;
    $o->{CONFIG}{FORCE_BUILD} = 0;
    $o->{CONFIG}{NAME} = '';
    $o->{CONFIG}{_INSTALL_} = 0;
    $o->{CONFIG}{WITH} = [];
    $o->{CONFIG}{AUTONAME} = 1;
    $o->{CONFIG}{REPORTBUG} = 0;
    $o->{CONFIG}{UNTAINT} = 0;
    $o->{CONFIG}{VERSION} = '';
    $o->{CONFIG}{BUILD_NOISY} = 1;
    $o->{INLINE}{ILSM_suffix} = $Config::Config{dlext};
    $o->{INLINE}{ILSM_module} = 'Inline::C';
    $o->{INLINE}{version} = $Inline::VERSION;
    $o->{INLINE}{ILSM_type} = 'compiled';
    $o->{INLINE}{DIRECTORY} = 'irrelevant_0';
    $o->{INLINE}{object_ready} = 0;
    $o->{INLINE}{md5} = 'irrelevant_1';
    $o->{API}{modfname} = $modfname;
    $o->{API}{script} = 'irrelevant_2';
    $o->{API}{location} = 'irrelevant_3';
    $o->{API}{language} = 'C';
    $o->{API}{modpname} = 'irrelevant_4';
    $o->{API}{directory} = 'irrelevant_5';
    $o->{API}{install_lib} = 'irrelevant_6';
    $o->{API}{build_dir} = $build_dir;
    $o->{API}{language_id} = 'C';
    $o->{API}{pkg} = $pkg;
    $o->{API}{suffix} = $Config::Config{dlext};
    $o->{API}{cleanup} = 1;
    $o->{API}{module} = $module;
    $o->{API}{code} = $code;

    # Check for invalid config options - and die if one is found
    for(keys(%$config_options)) { die "$_ is an invalid config option" if !check_config_keys($_)}

    if(exists($config_options->{BUILD_NOISY})) {$o->{CONFIG}{BUILD_NOISY} = $config_options->{BUILD_NOISY}}

    if($config_options->{AUTOWRAP}) {$o->{ILSM}{AUTOWRAP} = 1}

    if($config_options->{BOOT}) {$o->{ILSM}{XS}{BOOT} = $config_options->{BOOT}} 

    # This is what Inline::C does with the MAKE parameter ... so we'll do the same.
    # Not sure that this achieves anything in the context of InlineX::C2XS.
    if($config_options->{MAKE}) {$o->{ILSM}{MAKE} = $config_options->{MAKE}}

    if($config_options->{TYPEMAPS}) {
      unless(ref($config_options->{TYPEMAPS}) eq 'ARRAY') {die "TYPEMAPS must be passed as an array reference"}
      for(@{$config_options->{TYPEMAPS}}) {
         die "Couldn't locate the typemap $_" unless -e $_;
      }
      $o->{ILSM}{MAKEFILE}{TYPEMAPS} = $config_options->{TYPEMAPS}; 
    }

    if($config_options->{LIBS}) {
      unless(ref($config_options->{LIBS}) eq 'ARRAY') {die "LIBS must be passed as an array reference"}
      $o->{ILSM}{MAKEFILE}{LIBS} = $config_options->{LIBS}
    }

    if($config_options->{PREFIX}) {$o->{ILSM}{XS}{PREFIX} = $config_options->{PREFIX}}

    bless($o, 'Inline::C');

    Inline::C::validate($o);

    if($config_options->{AUTO_INCLUDE}) {$o->{ILSM}{AUTO_INCLUDE} .= $config_options->{AUTO_INCLUDE} . "\n"}

    if($config_options->{CC}) {$o->{ILSM}{MAKEFILE}{CC} = $config_options->{CC}}

    if($config_options->{CCFLAGS}) {$o->{ILSM}{MAKEFILE}{CCFLAGS} = " " . $config_options->{CCFLAGS}}

    if($config_options->{INC}) {$o->{ILSM}{MAKEFILE}{INC} .= " $config_options->{INC}"}

    if($config_options->{LD}) {$o->{ILSM}{MAKEFILE}{LD} = " " . $config_options->{LD}}

    if($config_options->{LDDLFLAGS}) {$o->{ILSM}{MAKEFILE}{LDDLFLAGS} = " " . $config_options->{LDDLFLAGS}}

    # Here, we'll add the MAKE parameter to $o->{ILSM}{MAKEFILE}{MAKE} ... which
    # could be useful (given that recent versions of Extutils::MakeMaker now recognise it):
    if($config_options->{MAKE}) {$o->{ILSM}{MAKEFILE}{MAKE} = $config_options->{MAKE}}

    if($config_options->{MYEXTLIB}) {$o->{ILSM}{MAKEFILE}{MYEXTLIB} = " " . $config_options->{MYEXTLIB}}

    if($config_options->{OPTIMIZE}) {$o->{ILSM}{MAKEFILE}{OPTIMIZE} = " " . $config_options->{OPTIMIZE}}

    if(!$need_inline_h) {$o->{ILSM}{AUTO_INCLUDE} =~ s/#include "INLINE.h"//i}

    _build($o, $need_inline_h);

    if($config_options->{WRITE_MAKEFILE_PL}) {
      if($config_options->{VERSION}) {$o->{API}{version} = $config_options->{VERSION}}
      else {warn "'VERSION' being set to '0.00' in the Makefile.PL. Did you supply a correct version number to c2xs() ?"}
      print "Writing Makefile.PL in the ", $o->{API}{build_dir}, " directory\n";
      $o->call('write_Makefile_PL', 'Build Glue 3');
    }
}

sub _build {
    my $o = shift;
    my $need_inline_headers = shift;
    
    $o->call('preprocess', 'Build Preprocess');
    $o->call('parse', 'Build Parse');

    print "Writing ", $o->{API}{modfname}, ".xs in the ", $o->{API}{build_dir}, " directory\n";
    $o->call('write_XS', 'Build Glue 1');

    if($need_inline_headers) {
      print "Writing INLINE.h in the ", $o->{API}{build_dir}, " directory\n";
      $o->call('write_Inline_headers', 'Build Glue 2');
    }
}

sub check_config_keys {
    for('AUTOWRAP', 'AUTO_INCLUDE', 'TYPEMAPS', 'LIBS', 'INC', 'VERSION', 'WRITE_MAKEFILE_PL',
        'BUILD_NOISY', 'BOOT', 'MAKE', 'PREFIX', 'CCFLAGS', 'LD', 'LDDLFLAGS', 'MYEXTLIB', 
        'OPTIMIZE', 'CC')
       {return 1 if $_ eq $_[0]} # it's a valid config option
    return 0;                    # it's an invalid config option
}

1;

__END__

=head1 NAME

InlineX::C2XS - Convert from Inline C code to XS.

=head1 SYNOPSIS

  use InlineX::C2XS qw(c2xs);

  my $module_name = 'MY::XS_MOD';
  my $package_name = 'MY::XS_MOD';

  # $build_dir is an optional third arg.
  # If omitted it defaults to '.' (the cwd).
  my $build_dir = '/some/where/else';

  # $config_opts is an optional fourth arg (hash reference)
  # See the "Recognised Hash Keys" section below.
  my $config_opts = {'AUTOWRAP' => 1,
                     'AUTO_INCLUDE' => 'my_header.h',
                     'TYPEMAPS' => ['my_typemap'],
                     'INC' => '-I/my/includes/dir',
                     'WRITE_MAKEFILE_PL' => 1,
                     'VERSION' => 0.42,
                     'LIBS' => ['-L/somewhere -lmylib'],
                     'BUILD_NOISY' => 0, # No Inline::C progress messages
                    };

  # Create /some/where/else/XS_MOD.xs from ./src/XS_MOD.c
  c2xs($module_name, $package_name, $build_dir);

  # Or create XS_MOD.xs in the cwd:
  c2xs($module_name, $package_name);

  The optional fourth arg (a reference to a hash) is to enable the
  writing of XS files using Inline::C's autowrap capability - and
  also to enable the creation of the Makefile.PL (if desired).
  See the "Recognised Hash Keys" section below.

  # Create XS_MOD.xs in the cwd, using the AUTOWRAP feature:
  c2xs($module_name, $package_name, '.', $config_opts);

=head1 DESCRIPTION
 
 Don't feed an actual Inline::C script to this module - it won't
 be able to parse it. It is capable of parsing correctly only
 that C code that is suitable for inclusion in an Inline::C
 script.

 For example, here is a simple Inline::C script:

  use warnings;
  use Inline C => Config =>
      BUILD_NOISY => 1,
      CLEAN_AFTER_BUILD => 0;
  use Inline C => <<'EOC';
  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }
  EOC

  greet();
  __END__

 The C file that InlineX::C2XS needs to find would contain only that code
 that's between the opening 'EOC' and the closing 'EOC' - namely:

  #include <stdio.h>

  void greet() {
      printf("Hello world\n");
  }

 InlineX::C2XS looks for the source file in ./src directory - expecting
 that the filename will be the same as what appears after the final '::'
 in the module name (with a '.c' extension). ie if your module is
 called My::Next::Mod the c2xs() function looks for a file ./src/Mod.c, 
 and creates a file named Mod.xs. Also created by the c2xs function, is
 the file 'INLINE.h' - but only if that file is needed. The generated 
 xs file (and INLINE.h) will be written to the cwd unless a third 
 argument (specifying a valid directory) is provided to the c2xs
 function

 The created XS file, when packaged with the '.pm' file, an
 appropriate 'Makefile.PL' (which can also be auto-generated by setting
 the WRITE_MAKEFILE_PL hash key), and 'INLINE.h' (if it's needed), can be 
 used to build the module in the usual way - without any dependence
 upon the Inline::C module.

=head1 Recognised Hash Keys

 As regards the optional fourth argument to c2xs(), the following hash
 keys are recognised:

  AUTO_INCLUDE
   The value specified is automatically inserted into the generated XS
   file. (Also, the specified include will be parsed iff AUTOWRAP
   is set to a true value.) eg:

    AUTO_INCLUDE => '#include <my_header.h>',
  ----

  AUTOWRAP
   Set this to a true value to enable Inline::C's AUTOWRAP capability.
   (There's no point in specifying a false value, as "false" is the 
   default anyway.) eg:

    AUTOWRAP => 1,
  ----

 BOOT
   Specifies C code to be executed in the XS BOOT section. Corresponds
   to the XS parameter. eg:

    BOOT => 'printf("Hello .. from bootstrap\n");',
  ----

  BUILD_NOISY
   Is set to a true value, by default. Setting to a false value will
   mean that progress messages generated by Inline::C are suppressed. eg:

    BUILD_NOISY => 0,
  ----

  CC
   Specify the compiler you want to use. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    CC => 'g++',
  ----

  CCFLAGS
   Specify which compiler flags to use. (Existing value gets clobbered, so
   you'll probably want to re-specify it.) It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    CCFLAGS => '-DMY_DEFINE ' . $Config{ccflags},
  ----

  INC
   The value specified is added to the includes search path. It makes
   sense to assign this key only when AUTOWRAP and/or WRITE_MAKEFILE_PL
   are set to a true value. eg:

    INC => '-I/my/includes/dir',
  ----

  LD
   Specify the linker you want to use.It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    LD => 'g++',
  ----

  LDDLFLAGS
   Specify which linker flags to use. (Existing value gets clobbered, so
   you'll probably want to re-specify it.) It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    LDDLFLAGS => "$my_ldopts " . $Config{lddlflags},
  ----

  LIBS
   The value(s) specified become the LIBS search path. It makes sense
   to assign this key only if WRITE_MAKEFILE_PL is set to a true value.
   (Must be an array reference.) eg
   
    LIBS => ['-L/somewhere -lsomelib', '-L/elsewhere -lotherlib'],
  ----

  MAKE
   Specify the make utility you want to use. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    MAKE => 'pmake', # I have no idea whether that will work :-)
  ----

  MYEXTLIB
   Specifies a user compiled object that should be linked in. 
   Corresponds to the MakeMaker parameter. It makes sense to assign this
   key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    MYEXTLIB => '/your/path/yourmodule.so',
  ----

  OPTIMIZE
   This controls the MakeMaker OPTIMIZE setting.It makes sense to assign
   this key only when WRITE_MAKEFILE_PL is set to a true value. eg:

    OPTIMIZE => '-g',
  ----

  PREFIX
   Specifies a prefix that will be automatically stripped from C 
   functions when they are bound to Perl. eg:

    PREFIX => 'FOO_',
  ----

  TYPEMAPS
   The value(s) specified are added to the list of typemaps. It makes
   sense to assign this key only when AUTOWRAP and/or WRITE_MAKEFILE_PL
   are set to a true value. (Must be an array reference.) eg:

    TYPEMAPS =>['my_typemap', 'my_other_typemap'],
  ----

  VERSION
   Set this to the version number of the module. It makes sense to assign
   this key only if WRITE_MAKEFILE_PL is set to a true value. eg:

    VERSION => 0.42,
  ----

  WRITE_MAKEFILE_PL
   Set this to to a true value if you want the Makefile.PL to be
   generated. (There's no point in specifying a false value, as "false"
   is the default anyway. You should also assign the 'VERSION' key to 
   the correct value when WRITE_MAKEFILE_PL is set.) eg:
    
    WRITE_MAKEFILE_PL => 1,
  ----

=head1 TODO

 Improve the t_makefile_pl test script. It currently provides strong 
 indication that everything is working fine ... but is not conclusive.
 (This might take forever.)  
  
=head1 BUGS

  None known - patches/rewrites/enhancements welcome.
  Send to sisyphus at cpan dot org

=head1 COPYRIGHT

  Copyright Sisyphus. You can do whatever you want with this code.
  It comes without any guarantee or warranty.

=cut

