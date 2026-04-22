package SubPar::Response;

use strict;
use warnings;

use SubPar::ContentType;

use JSON::PP;

use constant HTTP_200 => 200;
use constant HTTP_404 => 404;
use constant HTTP_500 => 500;

sub new {
    my ($class, $http_code, $content_type, $body) = @_;
    
    return bless {
        http_code    => $http_code,
        content_type => $content_type,
        body         => $body,
    }, $class;
}

sub to_psgi {
    my $self = shift;
    my $body = SubPar::ContentType::encode($self->{content_type}, $self->{body});

    return [
        $self->{http_code},
        ['Content-Type', $self->{content_type}],
        [$body]
    ];
}

1;