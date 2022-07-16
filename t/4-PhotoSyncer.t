use 5.032;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test::More;
use English '-no_match_vars';
use File::Spec::Functions qw( catfile catdir );
use Carp qw(croak);
use File::Temp;
use File::Copy qw( copy move );

use Test::Exception;
use Test::Lib;
use File::Slurp qw(read_dir);

BEGIN {
    $ENV{IN_TEST} = 1;
}

require_ok('Photo::Syncer');

use Photo::Syncer;

use Resources qw(resource);

sub setUpCameraDir (@extraDirs) {
    my $cameraDirName = File::Temp->newdir(
        TEMPLATE => 'TMP_PhotoSyncer_XXXXXXXXXX',
        TMPDIR => 1,
        RMDIR => 1
    );

    foreach my $name ( qw( 1 2 3 ) ) {
        my $fileName = "DSCF0792-$name.jpg";
        my $tmpPhoto = catfile( $cameraDirName, $fileName );
        if ( !copy( resource( @extraDirs, $fileName ), $tmpPhoto ) ) {
            croak 'Could no copy photo to temporal folder: ' . $tmpPhoto;
        }
    }

    return $cameraDirName;
}

sub setUpOutputDir {
    return File::Temp->newdir(
        TEMPLATE => 'TMP_PhotoSyncer_XXXXXXXXXX',
        TMPDIR => 1,
        RMDIR => 1
    );
}

my $mainDir = setUpCameraDir;
my $otherDir = setUpCameraDir('other2');
my $outputDir = setUpOutputDir;

my $ps = Photo::Syncer->new(
    syncPhotos => [
        catfile( $mainDir, 'DSCF0792-1.jpg' ),
        catfile( $otherDir, 'DSCF0792-1.jpg' ) ],
    outputDir  => $outputDir,
    depth      => 0,
    moveOption => 1
);

$ps->startProcess;

my $test = 'It has renamed and moved photos accordingly';
my @newPhotos = read_dir($outputDir);
my @expected = (
    '2022-06-19 (15_00_00) #2.jpg',
    '2022-06-19 (15_00_00).jpg',
    '2022-06-19 (15_00_01) #2.jpg',
    '2022-06-19 (15_00_01).jpg',
    '2022-06-19 (15_00_02) #2.jpg',
    '2022-06-19 (15_00_02).jpg',
);
is_deeply( [ sort @newPhotos ], [ sort @expected ], $test );

done_testing;
