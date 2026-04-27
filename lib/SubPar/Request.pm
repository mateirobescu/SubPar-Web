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
        body => $body,
        query_keys => undef, # lazy parsing
        route_params => {}, # retrieved and updated here when parsing the route
        cookies => undef, # lazy parsing

    }, $class;
}

sub method { $_[0]->{env}{REQUEST_METHOD} }

sub path { $_[0]->{env}{PATH_INFO} }

sub body { $_[0]->{body} }

sub env { $_[0]->{env} }

sub query {
    my ($self, $key) = @_;

    $self->{query_keys} //= _parse_query($self->{env});
    return $key ? $self->{query_keys}{$key} : { %{$self->{query_keys}} };
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

sub cookies {
    my ($self, $key) = @_;

    $self->{cookies} //= _parse_cookies($self->{env});
    return $key ? $self->{cookies}{$key} : { %{$self->{cookies}} };
}

sub route_params {
    my ($self, $key) = @_;

    return $key ? $self->{route_params}{$key} : { %{$self->{route_params}} };
}

sub remaining_path {
    my ($self) = @_;
    return $self->route_params("<PATH>");
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

sub header {
    my ($self, $name) = @_;
    $name = uc $name;
    $name =~ s/-/_/g;

    return $self->{env}{"HTTP_$name"};
}

1;

__END__

=head1 NAME

SubPar::Request - Represents an incoming HTTP request

=head1 SYNOPSIS

    sub handler {
        my ($self, $req) = @_;

        my $method  = $req->method;
        my $path    = $req->path;
        my $body    = $req->body;
        my $name    = $req->query('name');
        my $session = $req->cookie('session');
        my $token   = $req->header('Authorization');
        my $id      = $req->route_params('id');
        my $rest    = $req->remaining_path;
    }

=head1 DESCRIPTION

SubPar::Request wraps the PSGI environment hashref and provides a clean
API for accessing all parts of an incoming HTTP request. Query parameters
and cookies are parsed lazily on first access.

=head1 METHODS

=head2 method

    my $method = $req->method;

Returns the HTTP method e.g. C<GET>, C<POST>, C<PUT>, C<DELETE>.

=head2 path

    my $path = $req->path;

Returns the request path e.g. C</users/123>.

=head2 body

    my $body = $req->body;

Returns the decoded request body. JSON and form-encoded bodies are
automatically decoded into a hashref. Returns an empty string for
requests with no body.

=head2 query

    my $name = $req->query('name');
    my $all  = $req->query;

Returns a query parameter by name, or all query parameters as a hashref.
Values are URL decoded automatically.

=head2 cookie

    my $session = $req->cookie('session');
    my $all     = $req->cookie;

Returns a cookie value by name, or all cookies as a hashref.
Values are URL decoded automatically.

=head2 header

    my $token = $req->header('Authorization');
    my $type  = $req->header('Content-Type');

Returns a request header by name. The name is case insensitive and
dashes are converted to underscores automatically.

=head2 route_params

    my $id   = $req->route_params('id');
    my $name = $req->route_params('name');
    my $all  = $req->route_params;

Returns a dynamic route parameter by name, or all route parameters
as a hashref. Parameters are defined in the route path with C<:name>
syntax e.g. C</users/:id>.

=head2 remaining_path

    my $path = $req->remaining_path;

Returns the remaining path captured by a C<**> catch-all wildcard.
For example a route C</files/**> matching C</files/a/b/c> would
return C<a/b/c>.

=head2 env

    my $env = $req->env;

Returns the raw PSGI environment hashref. Use this to access any
PSGI variables not exposed by the other methods.

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut