use 5.032;
use experimental 'signatures';

use Object::Pad;

class GMTDiff {
    use Time::Local;

    sub getDifference {
        my @time = localtime time;
        return timegm(@time) - timelocal(@time);
    }
}
