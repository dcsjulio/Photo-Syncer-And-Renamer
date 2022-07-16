use 5.032;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test::More;
use English '-no_match_vars';
use File::Spec::Functions qw( catfile catdir );

use Test::Exception;
use Test::Lib;
use Const::Fast;

require_ok('Photo::CameraDir');

use Photo::CameraDir;
use Resources qw(resource);

my ( $test, $cameraDir, @expected, @result );

$test = 'Detects non-existing directory';
throws_ok {
    Photo::CameraDir->new( path => 'this-dir-doest-not-exist', depth => 0 );
} qr/ \b exist \b /sxm, $test;

$test = 'Detects invalid depth: negative number';
throws_ok {
    Photo::CameraDir->new( path => q(.), depth => -1 );
} qr/ \b valid \b /sxm, $test;

$test = 'Detects invalid depth: not-a-number';
throws_ok {
    Photo::CameraDir->new( path => q(.), depth => '1.' );
} qr/ \b valid \b /sxm, $test;

$test = 'Can get photos from resources dir - depth 0';
$cameraDir = Photo::CameraDir->new( path => resource, depth => 0 );
@expected = sort map { $_->path =~ s{\\}{/}sxmgr } $cameraDir->readPhotos;
@result = (
    't/resources/DSCF0792-1.jpg',
    't/resources/DSCF0792-2.jpg',
    't/resources/DSCF0792-3.jpg',
);
is_deeply( \@result, \@expected, $test );

$test = 'Can get photos from resources dir - depth 1';
$cameraDir = Photo::CameraDir->new( path => resource, depth => 1 );
@expected = sort map { $_->path =~ s{\\}{/}sxmgr } $cameraDir->readPhotos;
@result = (
    't/resources/DSCF0792-1.jpg',
    't/resources/DSCF0792-2.jpg',
    't/resources/DSCF0792-3.jpg',
    't/resources/other1/DSCF0792-1.jpg',
    't/resources/other1/DSCF0792-2.jpg',
    't/resources/other1/DSCF0792-3.jpg',
    't/resources/other2/DSCF0792-1.jpg',
    't/resources/other2/DSCF0792-2.jpg',
    't/resources/other2/DSCF0792-3.jpg',
);
is_deeply( \@result, \@expected, $test );

$test = 'Can get photos from resources dir - depth 2';
$cameraDir = Photo::CameraDir->new( path => resource, depth => 2 );
@expected = sort map { $_->path =~ s{\\}{/}sxmgr } $cameraDir->readPhotos;
@result = (
    't/resources/DSCF0792-1.jpg',
    't/resources/DSCF0792-2.jpg',
    't/resources/DSCF0792-3.jpg',
    't/resources/other1/DSCF0792-1.jpg',
    't/resources/other1/DSCF0792-2.jpg',
    't/resources/other1/DSCF0792-3.jpg',
    't/resources/other1/other2/DSCF0792-1.jpg',
    't/resources/other1/other2/DSCF0792-2.jpg',
    't/resources/other1/other2/DSCF0792-3.jpg',
    't/resources/other2/DSCF0792-1.jpg',
    't/resources/other2/DSCF0792-2.jpg',
    't/resources/other2/DSCF0792-3.jpg',
);
is_deeply( \@result, \@expected, $test );

done_testing;
