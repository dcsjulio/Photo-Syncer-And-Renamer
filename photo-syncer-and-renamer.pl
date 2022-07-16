#!/usr/bin/env perl

use 5.032;
use feature 'signatures';
no warnings 'experimental::signatures';

use Getopt::Long;
use English '-no_match_vars';

use File::Slurp qw(read_dir);

use lib 'lib';

use Photo::Syncer;

my ( @syncPhotos, %options, $help );

sub abortIt ($message) {
    say {*STDERR} "$message\n";
    exit 1;
}

sub printHelp {
    say q()
        . "$PROGRAM_NAME\n\n"
        . "Arguments:\n"
        . "  --help      : Prints this message\n"
        . '  --syncphoto : Specifies syncphoto.'
        . " Its parent directory willl be processed\n"
        . "  --dirdepth  : Depth of the directories (default: 0)\n"
        . "  --outdir    : Output directory\n"
        . '  --action    : Action when processing photos.'
        . " Valid values are: copy or move\n"
    ;

    return;
}

sub getArguments {
    my %gotOptions = (
        'syncphoto=s' => \@syncPhotos,
        'dirdepth=i'  => \$options{dirdepth},
        'outdir=s'    => \$options{outdir},
        'action=s'    => \$options{action},
        'help'        => \$help,
    );

    if ( !GetOptions(%gotOptions) ) {
        abortIt( q()
            . 'Error in arguments.'
            . ' Please use --help to see allowed arguments.'
        );
    }

    return;
}

sub validateArguments {
    foreach my $argument ( qw( dirdepth outdir action ) ) {
        if ( !defined $options{$argument} ) {
            abortIt( q()
                . "Argument $argument is mandatory."
                . ' Please use --help to see mandatory arguments.'
            );
        }
    }

    if ( @syncPhotos < 2 ) {
        abortIt('You must input at least two sync photos');
    }

    foreach my $file (@syncPhotos) {
        if ( !-f $file ) {
            abortIt("syncphoto '$file' does not exist");
        }
    }

    if ( $options{dirdepth} < 0 ) {
        abortIt('dirdepth cannot be negative');
    }

    if ( !-d $options{outdir} ) {
        abortIt("outdir '$options{outdir}' does not exist");
    }

    if ( read_dir( $options{outdir} )->@* > 0 ) {
        abortIt("outdir '$options{outdir}' must be empty");
    }

    if ( $options{action} ne 'copy' && $options{action} ne 'move' ) {
        abortIt("action '$options{action}' is not valid");
    }

    return;
}

## MAIN ##

getArguments;

if ($help) {
    printHelp;
    exit 0;
}

validateArguments;

my $syncer = Photo::Syncer->new(
    syncPhotos => \@syncPhotos,
    depth      => $options{dirdepth},
    outputDir  => $options{outdir},
    moveOption => $options{action} eq 'move',
);

say "\nPlease wait. This process may take a while...\n";

$syncer->startProcess;

say "\n\nDONE!";
