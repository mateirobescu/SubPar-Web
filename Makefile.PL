use strict; 
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebServer',
    VERSION          => '0.01',
    AUTHOR           => 'Matei-Gabriel Robescu',
    LICENSE          => 'mit',
    EXE_FILES        => ['bin/subpar'],
    PM               => {
        'lib/SubPar/Server.pm'      => '$(INST_LIB)/SubPar/Server.pm',
        'lib/SubPar/Response.pm'    => '$(INST_LIB)/SubPar/Response.pm',
        'lib/SubPar/ContentType.pm' => '$(INST_LIB)/SubPar/ContentType.pm',
        'lib/SubPar/Model.pm' => '$(INST_LIB)/SubPar/Model.pm',
        'lib/SubPar/Repository.pm' => '$(INST_LIB)/SubPar/Repository.pm',
        'lib/SubPar/Controller.pm' => '$(INST_LIB)/SubPar/Controller.pm',
        'lib/SubPar/Request.pm' => '$(INST_LIB)/SubPar/Request.pm',
    },
    PREREQ_PM        => {
        'JSON::PP'         => 0,
        'Starman'          => 0,
        'DBI'              => 0,
        'URI'              => 0,
    },
);