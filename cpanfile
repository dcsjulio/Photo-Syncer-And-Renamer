requires 'Const::Fast';
requires 'DateTime';
requires 'File::Find::Rule';
requires 'File::Slurp';
requires 'Image::ExifTool';
requires 'Object::Pad';
requires 'Term::ProgressBar';
requires 'Time::Local';
requires 'Try::Tiny';
 
on 'test' => sub {
    requires 'Test::Exception';
    requires 'Test::Lib';
    requires 'Const::Fast';
    requires 'Try::Tiny';
    requires 'File::Slurp';
};
