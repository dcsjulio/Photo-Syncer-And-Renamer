use 5.032;
use experimental 'signatures';
use Object::Pad;

class Photo::Syncer {
    use Carp qw(croak);
    use File::Spec;
    use File::Basename;

    use Term::ProgressBar;
    use Const::Fast;

    use Photo::Element;
    use Photo::CameraDir;
    use Photo::Catalog;

    our $VERSION = '0.1';

    has $syncPhotos :param;
    has $depth      :param;
    has $outputDir  :param;
    has $moveOption :param;

    has @cameraDirs;
    has $catalog;

    BUILD (%params) {
        my $masterPath = shift $syncPhotos->@*;
        my $master = Photo::Element->new( path => $masterPath );
        push @cameraDirs, Photo::CameraDir->new(
            path   => dirname($masterPath),
            depth  => $params{depth},
			offset => $master->offset,
        );

        foreach my $photoPath ( $syncPhotos->@* ) {
            my $slave = Photo::Element->new( path => $photoPath );
            push @cameraDirs, Photo::CameraDir->new(
                path    => dirname($photoPath),
                setDiff => $master->newDate - $slave->newDate,
                depth   => $params{depth},
				offset  => $slave->offset,
            );
        }

        $catalog = Photo::Catalog->new( path => $outputDir );

        return;
    }

    method startProcess {
        const my $MAX_PERCENT => 100;

        my @allPhotos = map { $_->readPhotos } @cameraDirs;
        my $step      = int( 1 + @allPhotos / $MAX_PERCENT );

        my $progressBar;

        if ( !exists $ENV{IN_TEST} ) {
            $progressBar = Term::ProgressBar->new( scalar @allPhotos );
        }

        my $processed = 0;
        foreach my $photo (@allPhotos) {
            if ($moveOption) {
                $catalog->moveWithNewName($photo);
            }
            else {
                $catalog->copyWithNewName($photo);
            }

            if ( ++$processed % $step == 0 && !exists $ENV{IN_TEST} ) {
                $progressBar->update($processed);
            }
        }

        if ( !exists $ENV{IN_TEST} ) {
            $progressBar->update( scalar @allPhotos );
        }

        return;
    }
}
