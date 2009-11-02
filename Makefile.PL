use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Library::Catalog::CCS',
    VERSION_FROM  => 'lib/Library/Catalog/CCS.pm',
    PREREQ_PM     => {
        'DateTime'       => 0.50,
        'WWW::Mechanize' => 1.60,
    },
#    ABSTRACT_FROM => 'lib/Library/Catalog/CCS.pm',
    AUTHOR        => 'Daniel Rench <citric@cubicone.tmetic.com>',
);
