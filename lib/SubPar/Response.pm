package SubPar::Response;

use strict;
use warnings;

use SubPar::ContentType;
use URI::Escape;

sub status {
    my ($class, $status_code) = @_;
    
    return bless {
        status_code => $status_code,
        header => [],
        content_type => SubPar::ContentType::CT_JSON(),
        body => {},
    }, $class;
}

sub header {
    my ($self, $header_key, $header_value) = @_;

    push @{$self->{header}}, ($header_key, $header_value);
    return $self;
}

sub cookies {
    my ($self, $cookie_key, $cookie_value, $cookie_settings) = @_;

    push @{$self->{header}}, ("Set-Cookie", _encode_cookie($cookie_key, $cookie_value, $cookie_settings));
    return $self;
}

sub _encode_cookie {
    my ($cookie_key, $cookie_value, $cookie_settings) = @_;

    my $result = uri_escape($cookie_key) . "=" . uri_escape($cookie_value) . ";";

    return $result unless defined $cookie_settings;

    for my $key ( keys %$cookie_settings) {
        my $val = $cookie_settings->{$key};
        $result .= ' ';
        $result .= $key;
        $result .= '=' . $val if $val ne '1'; 
        $result .= ';'
    }

    return $result;
}

sub content_type {
    my ($self, $content_type) = @_;

    $self->{content_type} = $content_type;
    return $self;
}

sub body {
    my ($self, $body) = @_;

    $self->{body} = $body;
    return $self;
} 


sub to_psgi {
    my $self = shift;

    my $body = SubPar::ContentType::encode($self->{content_type}, $self->{body});

    return [
        $self->{status_code},
        [
            @{$self->{header}},
            "Content-Type" => $self->{content_type}
        ],
        [$body]
    ];
}

1;

__END__

=head1 NAME

SubPar::Response - Represents an outgoing HTTP response

=head1 SYNOPSIS

    # simple - framework wraps hashref in 200 JSON automatically
    return { name => "Matei" };

    # full control - builder style
    return SubPar::Response->status(200)
        ->content_type(SubPar::ContentType::CT_JSON())
        ->header("X-Custom", "value")
        ->cookie("session", "abc123", { path => "/", httponly => 1 })
        ->body({ name => "gogu" });

    # HTML file
    return SubPar::Response->status(200)
        ->content_type(SubPar::ContentType::CT_HTML())
        ->body({ file => "./Template/index.html" });

    # HTML string
    return SubPar::Response->status(200)
        ->content_type(SubPar::ContentType::CT_HTML())
        ->body({ html => "<h1>Hello</h1>" });

=head1 DESCRIPTION

SubPar::Response provides a builder-style API for constructing HTTP
responses. All methods except C<to_psgi> return C<$self> so calls
can be chained. The default content type is C<application/json>.

=head1 METHODS

=head2 status

    my $res = SubPar::Response->status(200);
    my $res = SubPar::Response->status(404);

Creates a new response with the given HTTP status code. This is the
entry point for the builder chain.

=head2 content_type

    $res->content_type(SubPar::ContentType::CT_JSON);
    $res->content_type(SubPar::ContentType::CT_HTML);
    $res->content_type(SubPar::ContentType::CT_TEXT);

Sets the response content type. Defaults to C<application/json>.
Returns C<$self> for chaining.

=head2 header

    $res->header("X-Custom-Header", "value");
    $res->header("X-Request-Id", "abc123");

Adds a response header. Can be called multiple times to add multiple
headers. Returns C<$self> for chaining.

=head2 cookie

    $res->cookie("session", "abc123");
    $res->cookie("session", "abc123", {
        path     => "/",
        httponly => 1,
        secure   => 1,
    });

Sets a response cookie. Cookie key and value are URL encoded
automatically. Optional settings hashref supports C<path>,
C<httponly>, and C<secure>. Returns C<$self> for chaining.

=head2 body

    $res->body({ name => "gogu" });
    $res->body({ file => "./Template/index.html" });
    $res->body({ html => "<h1>Hello</h1>" });

Sets the response body. For JSON pass a hashref. For HTML pass a
hashref with either a C<file> key containing a file path or an
C<html> key containing an HTML string. Returns C<$self> for chaining.

=head2 to_psgi

    my $psgi = $res->to_psgi;

Converts the response to a PSGI-compatible arrayref. Called
automatically by the framework — you should not need to call
this directly.

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut