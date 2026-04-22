package SubPar::Controller;

use strict;
use warnings;

sub register {
    my ($class, $server) = @_;
    my $self = bless { server => $server }, $class;

    $self->repositories();
    $self->methods();
    return $self;
}

sub methods {
    {}
}

sub repositories {
    {}
}

sub get {
    my ($self, $path, $handler) = @_;
    $self->{server}->register_method("GET", $path, sub {
        # handle query params
        return $self->$handler();
    });
}

sub post {
    my ($self, $path, $handler) = @_;
    $self->{server}->register_method("POST", $path, sub {
        my ($body) = @_;

        return $self->$handler($body);
    });
}

sub put {
    my ($self, $path, $handler) = @_;
    $self->{server}->register_method("PUT", $path, $handler);
}

sub patch {
    my ($self, $path, $handler) = @_;
    $self->{server}->register_method("PATCH", $path, $handler);
}

sub del {
    my ($self, $path, $handler) = @_;
    $self->{server}->register_method("DELETE", $path, $handler);
}

1;