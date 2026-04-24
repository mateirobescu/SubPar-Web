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