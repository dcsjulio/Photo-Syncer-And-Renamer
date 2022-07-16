use 5.032;
use feature 'signatures';
no warnings 'experimental::signatures';

use English '-no_match_vars';
use File::Spec::Functions qw( catfile catdir );
use File::Temp;
use File::Copy;
use Carp qw(croak);
use Test::More;

use Test::Exception;
use Test::Lib;
use Const::Fast;
use Try::Tiny;

use Resources qw(resource);

require_ok('Photo::Element');

use Photo::Element;

const my $DEFAULT_DIFF => -100;

const my %PHOTO_DATES => (
    'DSCF0792-1.jpg' => 1_655_650_800,
    'DSCF0792-2.jpg' => 1_655_650_801,
    'DSCF0792-3.jpg' => 1_655_650_802,
);

my ( $test, $photo, $result, $expected, $photoName );

foreach my $ext ( qw( jpg jpeg raw raf ) ) {
    $test = uc($ext) . ' is supported';
    ok Photo::Element::supported("FOOBAR.$ext"), $test;
}

$test = 'FOOBAR is not supported';
ok !Photo::Element::supported('FOOBAR.foobar'), $test;

$test = 'Detects non-existing file';
throws_ok {
    Photo::Element->new( path => 'this-file-doest-not-exist' );
} qr/ \b exist \b /sxm, $test;

$test = 'Detects unsupported extension when creating object instance';
throws_ok {
    Photo::Element->new( path => resource('not-a-photo.txt') );
} qr/ \b extension \b /sxm, $test;

$test = 'Can get DateTime';
$photoName = 'DSCF0792-1.jpg';
$expected = $PHOTO_DATES{$photoName};
$photo = Photo::Element->new( path => resource($photoName) );
$result = $photo->newDate;
is $result, $expected, $test;

$test = 'Can get CreateDate over DateTime';
$photoName = 'DSCF0792-2.jpg';
$expected = $PHOTO_DATES{$photoName};
$photo = Photo::Element->new( path => resource($photoName) );
$result = $photo->newDate;
is $result, $expected, $test;

$test = 'Can get DateTimeOriginal over CreateDate';
$photoName = 'DSCF0792-3.jpg';
$expected = $PHOTO_DATES{$photoName};
$photo = Photo::Element->new( path => resource($photoName) );
$result = $photo->newDate;
is $result, $expected, $test;

$test = 'Can get expected new date';
$photoName = 'DSCF0792-3.jpg';
$expected = $PHOTO_DATES{$photoName} + $DEFAULT_DIFF;
$photo = Photo::Element->new(
    path => resource('DSCF0792-3.jpg'),
    diff => $DEFAULT_DIFF
);
$result = $photo->newDate;
is $result, $expected, $test;

$test = 'New date is expected';
ok $photo->needsNewDate, $test;

$test = 'Can update and add new timedate';
try {
    my $dirTmp = File::Temp->newdir(
        TEMPLATE => 'TMP_PhotoElement_XXXXXXXXXX',
        TMPDIR => 1,
        RMDIR => 1
    );

    $photoName = 'DSCF0792-3.jpg';
    my $tmpPhoto = catfile( $dirTmp, $photoName );
    if ( !copy( resource('DSCF0792-3.jpg'), $tmpPhoto ) ) {
        croak 'Could no copy photo to temporal folder: ' . $tmpPhoto;
    }

    $photo = Photo::Element->new( path => $tmpPhoto, diff => $DEFAULT_DIFF );
    $photo->setNewDate;
    $photo->commit;

    $photo = Photo::Element->new( path => $tmpPhoto );
    $result = $photo->newDate;

    $expected = $PHOTO_DATES{$photoName} + $DEFAULT_DIFF;

    is $result, $expected, $test;
} catch {
    fail $test;
    croak "Last error: $_";
};

done_testing;
