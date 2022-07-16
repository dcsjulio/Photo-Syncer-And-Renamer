package Resources;

use strict;
use warnings;
use English '-no_match_vars';
use Exporter 'import';
use File::Spec::Functions qw( catdir catfile );
use File::Basename;

our @EXPORT_OK = qw(resource);

my $RESOURCES = catdir( dirname($PROGRAM_NAME), 'resources' );

sub resource {
    my @params = @_;
    return catfile $RESOURCES, @params;
}

1;