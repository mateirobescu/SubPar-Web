package SubPar::Response;

use strict;
use warnings;

use JSON::PP;

use constant HTTP_200 => "200 OK";
use constant HTTP_404 => "404 Not Found";
use constant HTTP_500 => "500 Internal Server Error";

sub new {
    my ($class, $http_code, $content_type, $body) = @_;
    
    return bless {
        http_code    => $http_code,
        content_type => $content_type,
        body         => $body,
    }, $class;
}

sub send {
    my ($self, $client) = @_;

    my $response = ContentType::encode($self->{content_type}, $self->{body});

    print $client "HTTP/1.1 " . $self->{http_code} . "\r\n";
    print $client "Content-Type: " . $self->{content_type} . "\r\n";
    print $client "Content-Length: " . length($response) . "\r\n";
    print $client "\r\n";
    print $client $response;
}

sub to_psgi {
    my $self = shift;
    my $body = ContentType::encode($self->{content_type}, $self->{body});

    return [
        $self->{http_code},
        ['Content-Type', $self->{content_type}],
        [$body]
    ];
}

1;