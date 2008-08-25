package MyMod;
use strict;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$MyMod::VERSION = '0.01';

DynaLoader::bootstrap MyMod $MyMod::VERSION;

@MyMod::EXPORT = ();
@MyMod::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
