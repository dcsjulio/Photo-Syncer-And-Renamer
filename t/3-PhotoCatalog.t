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
use Const::Fast;
use Try::Tiny;

require_ok('Photo::Catalog');
require_ok('Photo::CameraDir');

use Photo::Catalog;
use Photo::CameraDir;
use Resources qw(resource);

const my $DEFAULT_DIFF => 1000;

sub setUpCameraDir ($diff) {
    # Create a CameraDir directory and copy some photos there
    my $cameraDirName = File::Temp->newdir(
        TEMPLATE => 'TMP_CameraDir_XXXXXXXXXX',
        TMPDIR => 1,
        RMDIR => 1
    );

    foreach my $name ( qw( 1 2 3 ) ) {
        my $fileName = "DSCF0792-$name.jpg";
        my $tmpPhoto = catfile( $cameraDirName, $fileName );
        if ( !copy( resource($fileName), $tmpPhoto ) ) {
            croak 'Could no copy photo to temporal folder: ' . $tmpPhoto;
        }
    }

    return Photo::CameraDir->new(
        path => $cameraDirName,
        diff => $diff,
        depth => 0
    );
}

sub setUpCatalogDir {
    my $catalogDir = File::Temp->newdir(
        TEMPLATE => 'TMP_Catalog_XXXXXXXXXX',
        TMPDIR => 1,
        RMDIR => 1
    );

    return Photo::Catalog->new( path => $catalogDir );
}

sub setUpCameraAndCatalogDirs ( $test, $diff = 0, $quantity = 1 ) {
    my ( @cameraDir, $catalogDir );

    try {
        # Create a CameraDir directory and copy some photos there
        foreach my $num ( 1 .. $quantity ) {
            push @cameraDir, setUpCameraDir($diff);
        }

        # Prepare catalog
        $catalogDir = setUpCatalogDir;
    } catch {
        fail $test;
        croak "Last error: $_";
    };

    return ( @cameraDir, $catalogDir );
}

my ( $test, $testMessage, @expected );

$test = 'Detects non-existing directory';
throws_ok {
    Photo::Catalog->new( path => 'this-directory-doest-not-exist' );
} qr/ \b exist \b /sxm, $test;

$test = 'Detects directory that is not empty';
throws_ok {
    Photo::Catalog->new( path => resource );
} qr/ \b empty \b /sxm, $test;

# Test: copies and renames photos
my ( $cameraDir, $catalog ) = setUpCameraAndCatalogDirs( $test, $DEFAULT_DIFF );
my @photos = $cameraDir->readPhotos;
my @newPhotos;
foreach my $photo (@photos) {
    my $newPhoto = $catalog->copyWithNewName($photo);

    $test = sprintf 'Can copy %s', $photo->fileName;
    ok -e $newPhoto->path, $test;

    $testMessage = 'Can find file %s on destination folder after copying';
    $test = sprintf $testMessage, $photo->fileName;
    ok -e File::Spec->catfile( $catalog->path, $newPhoto->fileName ), $test;

    $test = sprintf 'Keeps original %s', $photo->fileName;
    ok -e $photo->path, $test;

    $test = sprintf 'Copied photo has same diff %s', $photo->fileName;
    is $photo->diff, $newPhoto->diff, $test;

    push @newPhotos, $newPhoto->fileName;
}

$test = 'It has renamed photos accordingly';
@expected = (
    '2022-06-19 (15_00_00).jpg',
    '2022-06-19 (15_00_01).jpg',
    '2022-06-19 (15_00_02).jpg',
);
is_deeply( \@newPhotos, \@expected, $test );

# Test: can move and handle same name
my ( $camDir1, $camDir2, $catalogDir ) = setUpCameraAndCatalogDirs( $test, 2, 2 );
my @destinationPhotos;
foreach my $photo ( $camDir1->readPhotos, $camDir2->readPhotos ) {
    my $newPhoto = $catalogDir->moveWithNewName($photo);

    $test = sprintf 'Can move %s', $photo->fileName;
    ok -e $newPhoto->path, $test;

    $testMessage = 'Can find file %s on destination folder after moving';
    $test = sprintf $testMessage, $photo->fileName;
    ok -e File::Spec->catfile( $catalogDir->path, $newPhoto->fileName ), $test;

    $test = sprintf 'Deletes original %s', $photo->fileName;
    ok !-e $photo->path, $test;

    $test = sprintf 'Moved photo has same diff %s', $photo->fileName;
    is $photo->diff, $newPhoto->diff, $test;

    push @destinationPhotos, $newPhoto->fileName;
}

$test = 'It has renamed photos accordingly, takes care of duplicates';
@expected = (
    '2022-06-19 (15_00_00).jpg',
    '2022-06-19 (15_00_01).jpg',
    '2022-06-19 (15_00_02).jpg',
    '2022-06-19 (15_00_00) #2.jpg',
    '2022-06-19 (15_00_01) #2.jpg',
    '2022-06-19 (15_00_02) #2.jpg',
);
is_deeply( \@destinationPhotos, \@expected, $test );

done_testing;
