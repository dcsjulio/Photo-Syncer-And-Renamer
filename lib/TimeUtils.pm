use 5.032;
use experimental 'signatures';

use Object::Pad;

class TimeUtils {
    use Time::Local;
	use Carp qw(croak);
	use Const::Fast;

	const our $ZERO_OFFSET => '+00:00';

	const my $SPH => 3600;
	const my $SPM => 60;

    sub getGMTDifference {
        my @time = localtime time;
        return timegm(@time) - timelocal(@time);
    }

	sub offsetToSeconds ($offset) {
		if ( $offset =~ /^([-+])([0-9]{2}):([0-9]{2})$/sxm ) {
			return ( $2 * $SPH + $3 * $SPM ) * ( $1 eq '-' ? -1 : 1 );
		}

		croak "Unexpected Exif offset format: '$offset'";
	}
}
