use 5.032;
use experimental 'signatures';
use Object::Pad;

class Photo::Catalog {
    use Carp qw(croak);
    use File::Spec;
    use File::Copy;

    use DateTime;
    use File::Find::Rule;
    use Try::Tiny;
    use File::Slurp qw(read_dir);

    use Photo::Element;

    our $VERSION = '0.1';

    sub _validate (%params) {
        if ( !-d $params{path} ) {
            croak "'$params{path}' does not exist";
        }

        if ( read_dir( $params{path} )->@* > 0 ) {
            croak "Directory '$params{path}' is not empty";
        }

        return;
    }

    has $path :param :reader;

    has %uniqueNames;

    BUILD (%params) {
        _validate(%params);
        return;
    }

    method copyWithNewName ($photo) {
        return $self->_addWithNewName( $photo, 1 );
    }

    method moveWithNewName ($photo) {
        return $self->_addWithNewName( $photo, 0 );
    }

    method _addWithNewName ( $photo, $doCopy ) {
        my $name = $self->_requestUniqueDateName(
            $photo->newDate,
            $photo->extension
        );
        my $newDestination = File::Spec->catfile( $path, $name );

        if ( -e $newDestination ) {
            croak "'$newDestination' exists, this was not expected";
        }

        $self->_safeCopyMove( $photo, $doCopy, $newDestination );

        return Photo::Element->new(
            path => $newDestination,
            diff => $photo->diff
        );
    }

    method _safeCopyMove ( $photo, $doCopy, $newDestination ) {
        my $wasOk = 1;
        try {
            if ($doCopy) {
                $wasOk = copy( $photo->path, $newDestination );
            }
            else {
                $wasOk = move( $photo->path, $newDestination );
            }
        } catch {
            $wasOk = 0;
        };

        if ( !$wasOk ) {
            croak sprintf 'Could not copy/move file "%s" as "%s"'
                , $photo->path
                , $newDestination;
        }
        return;
    }

    method _requestUniqueDateName ( $newDate, $extension ) {
        my $ext = lc $extension;
        my $dt = DateTime->from_epoch( epoch => $newDate );
        my $formattedDate = sprintf '%s (%s)', $dt->ymd, $dt->hms(q(_));

        my $finalName;
        if (   exists $uniqueNames{$formattedDate}
            && exists $uniqueNames{$formattedDate}{$ext} )
        {
            $uniqueNames{$formattedDate}{$ext}++;
            $finalName = sprintf '%s #%s.%s'
                , $formattedDate
                , $uniqueNames{$formattedDate}{$ext}
                , $ext;
        }
        else {
            $uniqueNames{$formattedDate}{$ext} = 1;
            $finalName = sprintf '%s.%s', $formattedDate, $ext;
        }

        return $finalName;
    }
}
