package SubPar::ContentType;

use strict;
use warnings;

use JSON::PP;

use constant CT_JSON => 'application/json';
use constant CT_TEXT => 'text/plain';
use constant CT_HTML => 'text/html';

sub encode {
    my ($content_type, $data) = @_;
    if ($content_type eq CT_JSON) {
        return encode_json($data);
    }
    return $data;
}

sub decode {
    my ($content_type, $data) = @_;

    if ($content_type eq CT_JSON) {
        return decode_json($data);
    }
    return $data;
}

1;