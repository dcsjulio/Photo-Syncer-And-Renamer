use 5.032;
use experimental 'signatures';
use Object::Pad;

class Photo::CameraDir {
    use Carp qw(croak);
    use File::Spec;

    use File::Find::Rule;

    use Photo::Element;

    our $VERSION = '0.1';

    sub _validate (%params) {
        if ( !-d $params{path} ) {
            croak "'$params{path}' does not exist";
        }

        if ( exists $params{depth} && $params{depth} !~ m{^[0-9]++$}sxm ) {
            croak "'$params{depth}' is not a valid number";
        }

        return;
    }

    has $path    :param;
    has $depth   :param;
    has $setDiff :param = 0;

    BUILD (%params) {
        _validate(%params);
        return;
    }

    method readPhotos {
        my $finder = File::Find::Rule->new
            ->file
            ->maxdepth( $depth + 1 )
            ->exec( sub { return Photo::Element::supported $_ } );

        my @photos =
            sort { uc $a->fileName cmp uc $b->fileName }
            map { Photo::Element->new( path => $_, diff => $setDiff ) }
            $finder->in($path);

        return @photos;
    }
}
