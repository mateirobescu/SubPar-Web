package SubPar::Request;

use strict; 
use warnings;

use SubPar::ContentType;
use URI::Escape;

sub new {
    my ($class, $env) = @_;

    my $body = '';
    if($env->{CONTENT_LENGTH}) {
        $env->{"psgi.input"}->read($body, $env->{CONTENT_LENGTH});
        $body = SubPar::ContentType::decode($env->{CONTENT_TYPE}, $body);
    }

    return bless {
        env => $env,
        method => $env->{REQUEST_METHOD},
        path => $env->{PATH_INFO},
        body => $body,
        query_keys => undef, # lazy parsing
        cookies => undef, # lazy parsing

    }, $class;
}

sub method { $_[0]->{method} }

sub path { $_[0]->{path} }

sub body { $_[0]->{body} }

sub env { $_[0]->{env} }

sub query {
    my ($self, $key) = @_;

    $self->{query_keys} //= _parse_query($self->{env});
    return $self->{query_keys}{$key};
}

sub _parse_query {
    my ($env) = @_;
    return {} unless $env->{QUERY_STRING};
    
    my $query_keys = {};
    for my $pair (split /&/, $env->{QUERY_STRING}) {
        my ($key, $val) = split /=/, $pair, 2;
        $query_keys->{uri_unescape($key)} = uri_unescape($val // '');
    }
    return $query_keys;
}

sub cookie {
    my ($self, $key) = @_;

    $self->{cookies} //= _parse_cookies($self->{env});
    return $self->{cookies}{$key};
}

sub _parse_cookies {
    my ($env) = @_;
    return {} unless $env->{HTTP_COOKIE};

    my $cookie_keys = {};
    for my $pair (split /;\s*/, $env->{HTTP_COOKIE}) {
        my ($key, $val) = split /=/, $pair, 2;
        $cookie_keys->{uri_unescape($key)} = uri_unescape($val // '');
    }
    return $cookie_keys;
}

sub headers {
    my ($self, $name) = @_;
    $name = uc $name;
    $name =~ s/-/_/g;

    return $self->{env}{"HTTP_$name"};
}

1;