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

sub add_repo {
    my ($self, $repo_name, $repo) = @_;

    if(exists $self->{repositories}{$repo_name}){
        die "$repo_name: a repository with this name already exists!";
    }

    $self->{repositories}{$repo_name} = $repo;
}

sub get_repo {
    my ($self, $repo_name) = @_;

    unless(exists $self->{repositories}{$repo_name}){
        die "$repo_name: a repository with this name doesn't exist!";
    }

    return $self->{repositories}{$repo_name};
}


sub add_route {
    my ($self, $method, $path, $handler) = @_;
    $self->{server}->_register_route($method, $path, sub {
        my ($request) = @_;
        return $self->$handler($request);
    });
}

sub server {
    my ($self) = @_;

    return $self->{server};
}

sub get_db {
    my ($self, $name) = @_;

    return $self->server->get_db($name);
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

__END__

=head1 NAME

SubPar::Controller - Base class for SubPar controllers

=head1 SYNOPSIS

    package Controller::UserController;
    use parent 'SubPar::Controller';

    sub repositories {
        my ($self) = @_;
        $self->{repositories}{User} = Repository::UserRepository->new($self->{server}->get_db("main"));
    }

    sub routes {
        my ($self) = @_;
        $self->get("/users",     \&index);
        $self->post("/users",    \&create);
        $self->put("/users/:id", \&update);
        $self->del("/users/:id", \&delete);
    }

    sub index {
        my ($self, $req) = @_;
        return { status => "ok" };
    }

=head1 DESCRIPTION

SubPar::Controller is the base class for all controllers. It provides
route registration helpers and dependency injection for repositories.
Subclass it and override C<routes> and optionally C<repositories>.

=head1 METHODS

=head2 register

    Controller::MyController->register($server);

Creates a new controller instance, injects the server, calls
C<repositories> and C<routes>. Called once at startup in C<app.psgi>.

=head2 repositories

    sub repositories {
        my ($self) = @_;
        $self->{repositories}{User} = Repository::UserRepository->new(...);
    }

Override to inject repositories into the controller. Optional.

=head2 routes

    sub routes {
        my ($self) = @_;
        $self->get("/path", \&handler);
    }

Override to register your routes. Required.

=head2 add_route

    $self->add_route("GET", "/users", \&handler);
    $self->add_route("GET", "/users/:id", \&handler);
    $self->add_route("GET", "/files/**", \&handler);

Register a route with any HTTP method. 
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

=head2 get

    $self->get("/users", \&handler);
    $self->get("/users/:id", \&handler);
    $self->get("/files/**", \&handler);

Register a GET route. 
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

=head2 post

    $self->post("/users", \&handler);
    $self->post("/users/:id", \&handler);

Register a POST route. 
Request body is accessible via C<$req-E<gt>body>.
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

=head2 put

    $self->put("/users/:id", \&handler);

Register a PUT route. Typically used for full resource updates.
Request body is accessible via C<$req-E<gt>body>.
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

=head2 patch

    $self->patch("/users/:id", \&handler);

Register a PATCH route. Typically used for partial resource updates.
Request body is accessible via C<$req-E<gt>body>.
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

=head2 del

    $self->del("/users/:id", \&handler);

Register a DELETE route. 
Dynamic segments C<:name> are accessible via C<$req-E<gt>route_params('name')>.
Catch-all C<**> is accessible via C<$req-E<gt>remaining_path>. 
Note: C<**> must be at the end of the path.

Note: C<del> is used instead of C<delete> as C<delete> is a Perl builtin.

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut
