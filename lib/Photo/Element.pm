use 5.032;
use experimental 'signatures';
use Object::Pad;

class Photo::Element {
    use Carp qw(croak);
    use File::Spec;

    use Const::Fast;
    use Image::ExifTool;

    use TimeUtils;

    our $VERSION = '0.1';

    const my $GMT_DIFF => TimeUtils::getGMTDifference();

    const my %C_ALLOWED_FORMATS => map { $_ => 1 } qw(
        360  DR4  IIQ  MPO  PSB
        3G2  DVB  IND  MQV  PSD
        3GP  EPS  INSP MRW  QTIF
        AAX  ERF  JNG  NEF  RAF
        AI   EXIF JP2  NKSC RAW
        ARQ  EXV  JPEG NRW  RW2
        ARW  F4A  JPG  ORF  RWL
        AVIF FFF  LRV  ORI  SR2
        CR2  FLIF M4A  PBM  SRW
        CR3  GIF  MEF  PDF  THM
        CRM  GPR  MIE  PEF  TIFF
        CRW  HDP  MNG  PGM  VRD
        CS1  HEIC MOS  PNG  WDP
        DCP  HEIF MOV  PPM  X3F
        DNG  ICC  MP4  PS   XMP
    );

    sub extractExtension ($fileName) {
        if ( $fileName =~ m/[.]([^.]*)$/sxm ) {
            return $1;
        }
        croak "Could not extract extensions from file $fileName";
    }

    sub supported ( $filePath = q() ) {
        my $ext = extractExtension($filePath);
        return exists $C_ALLOWED_FORMATS{ uc $ext };
    }

    sub _validate ($filePath) {
        if ( !-f $filePath ) {
            croak "$filePath does not exist";
        }

        if ( !supported($filePath) ) {
            croak "The extension for '$filePath' is not supported";
        }

        return;
    }

    has $path           :param :reader;
    has $diff           :param :reader = 0;
    has $expectedOffset :param :reader = $TimeUtils::ZERO_OFFSET;

    has $fileName  :reader;
    has $newDate   :reader;
    has $extension :reader;
    has $offset    :reader;

    has $exifTool;

    BUILD (%params) {
        _validate( $params{path} );
        return;
    }

    ADJUST {
        $exifTool = Image::ExifTool->new;
        $exifTool->Options( DateFormat => '%s' );
        $exifTool->ExtractInfo($path);

        my ( $volume, $dirs, $file ) = File::Spec->splitpath($path);
        $fileName = $file;

        my $date = $exifTool->GetValue('DateTimeOriginal')
                // $exifTool->GetValue('CreateDate')
                // $exifTool->GetValue('ModifyDate');

        if ( !$date ) {
            croak "Could not extract date from exif for file: '$path'";
        }

        $offset = $exifTool->GetValue('OffsetTime')
                // $exifTool->GetValue('OffsetTimeOriginal')
                // $exifTool->GetValue('OffsetTimeDigitized')
                // $TimeUtils::ZERO_OFFSET;

        # Calcualte and add offsets:
        #
        # GMT_DIFF is always added because when exifTool extracts the date
        # it always returns the epoch time for GMT time
        # (removes *machine* timezone)
        #
        # extraOffset exists because some cameras do store 'offset' exif flag
        # in a different way for photos and videos. For example Google Pixel 6a:
        # It stores exif offset for photos but it does not for videos.
        # So we need to normalize the offset for all the items.

        my $extraOffset = $expectedOffset eq $offset
            ? 0
            : TimeUtils::offsetToSeconds($expectedOffset);

        $newDate = $date + $diff + $GMT_DIFF + $extraOffset;

        $extension = extractExtension($path);


        return;
    }

    method needsNewDate {
        return $diff != 0;
    }

    method setNewDate {
        my @tags = qw( DateTimeOriginal CreateDate ModifyDate );
        foreach my $tag (@tags) {
            $exifTool->SetNewValue( $tag, $newDate );
        }
        return;
    }

    method commit {
        if ( !$exifTool->WriteInfo($path) ) {
            croak "Could not write metadata info for $path";
        }
        return;
    }
}
