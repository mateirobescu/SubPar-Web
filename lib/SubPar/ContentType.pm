package SubPar::ContentType;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(CT_JSON CT_TEXT CT_HTML CT_FORM);

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


    return $data;
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

__END__

=head1 NAME

SubPar::ContentType - Content type constants and encode/decode utilities

=head1 SYNOPSIS

    use SubPar::ContentType qw(CT_JSON CT_HTML CT_TEXT CT_FORM);

    # encoding
    my $json = SubPar::ContentType::encode(CT_JSON, { name => "gogu" });
    my $html = SubPar::ContentType::encode(CT_HTML, { file => "./index.html" });
    my $html = SubPar::ContentType::encode(CT_HTML, { html => "<h1>Hello</h1>" });

    # decoding
    my $data = SubPar::ContentType::decode(CT_JSON, $raw_json);
    my $data = SubPar::ContentType::decode(CT_FORM, $form_data);

=head1 CONSTANTS

=head2 CT_JSON

    application/json

=head2 CT_TEXT

    text/plain

=head2 CT_HTML

    text/html

=head2 CT_FORM

    application/x-www-form-urlencoded

=head1 METHODS

=head2 encode

    my $encoded = SubPar::ContentType::encode($content_type, $data);

Encodes C<$data> according to C<$content_type>.

For C<CT_JSON> — encodes a hashref to a JSON string.

For C<CT_HTML> — accepts a hashref with either a C<file> key containing
a file path to read from, or an C<html> key containing an HTML string.
Dies if neither key is present.

=head2 decode

    my $decoded = SubPar::ContentType::decode($content_type, $data);

Decodes C<$data> according to C<$content_type>.

For C<CT_JSON> — decodes a JSON string into a hashref.

For C<CT_FORM> — decodes a URL encoded form string into a hashref.
Keys and values are URL unescaped automatically.

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut