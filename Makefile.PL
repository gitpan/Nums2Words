use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     'NAME'      => 'Lingua::EN::Nums2Words',
     'DISTNAME'  => 'Nums2Words',
     'VERSION_FROM'   => 'Nums2Words.pm',
     'dist'      => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'}
);

print "\n";
print "Please take a moment to review the license.\n\n";
print "Do a 'make test' to test the module before installation\n";
print "Do a 'make install' to install the module.\n";

