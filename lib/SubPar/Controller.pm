package SubPar::Controller;

use strict;
use warnings;

sub register {
    my ($class, $server) = @_;
    my $self = bless { server => $server }, $class;

    $self->repositories();
    $self->routes();
    return $self;
}

sub routes {}

sub repositories {}

sub add_route {
    my ($self, $method, $path, $handler) = @_;
    $self->{server}->_register_method($method, $path, sub {
        my ($request) = @_;
        return $self->$handler($request);
    });
}

sub get {
    my ($self, $path, $handler) = @_;
    $self->add_route("GET", $path, $handler);
}

sub post {
    my ($self, $path, $handler) = @_;
    $self->add_route("POST", $path, $handler);
}

sub put {
    my ($self, $path, $handler) = @_;
    $self->add_route("PUT", $path, $handler);
}

sub patch {
    my ($self, $path, $handler) = @_;
    $self->add_route("PATCH", $path, $handler);
}

sub del {
    my ($self, $path, $handler) = @_;
    $self->add_route("DELETE", $path, $handler);
}

1;