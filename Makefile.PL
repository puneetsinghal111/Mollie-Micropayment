use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mollie::Micropayment',
    VERSION_FROM      => 'lib/Mollie/Micropayment.pm', # finds $VERSION
    AUTHOR       	  => 'C. Kras <ckras@cpan.org>',
    ABSTRACT     	  => 'API for Mollie.nl micropayments',
    PREREQ_PM         => {'XML::Simple' => 0,
    				      'LWP::Simple' => 0}
);
