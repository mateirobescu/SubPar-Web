package SubPar::ContentType;

use strict;
use warnings;

use JSON::PP;
use URI::Escape;

use constant CT_JSON => 'application/json';
use constant CT_TEXT => 'text/plain';
use constant CT_HTML => 'text/html';
use constant CT_FORM => 'application/x-www-form-urlencoded';

sub encode {
    my ($content_type, $data) = @_;
    if ($content_type eq CT_JSON) {
        return encode_json($data);
    }
    
    if ($content_type eq CT_HTML) {
        if($data->{file}) {
            open my $fh, '<', $data->{file} or die "Cannot open file: $data->{file} - $!";
            local $/;
            return <$fh>;
        } elsif ($data->{html}) {
            return $data->{html};
        }  else {
            die "CT_HTML requires either 'file' or 'html' key in data";
        }
    }


    return Dumper $data;
}

sub decode {
    my ($content_type, $data) = @_;

    if ($content_type eq CT_JSON) {
        return decode_json($data);
    }

    if ($content_type eq CT_FORM) {
        my %params;
        for my $pair (split /&/, $data) {
            my ($key, $value) = split /=/, $pair;
            $params{uri_unescape($key)} = uri_unescape($value // '');
        }

        return \%params;
    }

    return $data;
}

1;