package SubPar::Server;

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;
use DBI;
use DBIx::Connector;

use SubPar::ContentType;
use SubPar::Response;
use SubPar::Request;

sub new {
    my ($class, $self) = @_;
    
    return bless { routes => {}, databases => {} }, $class;
}

sub load_controllers {
    my ($self) = @_;

    for my $file (glob "./Controller/*.pm") {
        (my $package = $file) =~ s/^\.\///;
        $package =~ s/\.pm$//;
        $package =~ s/\//::/g;

        require $file;
        $package->register($self);
    }
}

sub _register_route {
    my ($self, $method, $path, $sub) = @_;

    $path =~ s/^\///;
    $path =~ s/\/$//;
    my @path_segments = split /\//, $path;

    my $pointer = $self->{routes};
    for my $segment (@path_segments) {
        if(substr($segment, 0, 1) eq ":") {
            my $param_name = substr($segment, 1);
            if (exists $pointer->{"*"} && $pointer->{"*"}{"<PARAM_NAME>"} ne $param_name) {
                die "Ambiguous dynamic route: $method - $path";
            }

            $pointer->{"*"} = {} unless exists $pointer->{"*"};
            $pointer = $pointer->{"*"};
            $pointer->{"<PARAM_NAME>"} = $param_name;
        }
        elsif($segment eq "**") {
            die "** caputre all wildcard must be at the end of the path: $method - $path" unless $path =~ /\*\*$/;

            $pointer->{"**"} = {} unless exists $pointer->{"**"};
            $pointer = $pointer->{"**"};
            $pointer->{"<CAPTURE_ALL>"} = 1;
        }
        else {
            $pointer->{$segment} = {} unless exists $pointer->{$segment};
            $pointer = $pointer->{$segment};
        }
    }

    die "Route already exists: $method - $path" if defined $pointer->{"<$method>"};
    $pointer->{"<$method>"} = $sub;
}

sub _find_route {
    my ($self, $request) = @_;
    my ($method, $path) = ($request->method, $request->path);

    $path =~ s/^\///;
    $path =~ s/\/$//;
    my @path_segments = split /\//, $path;

    my $pointer = $self->{routes};
    while(@path_segments > 0) {
        my $segment = shift @path_segments;

        if(exists $pointer->{$segment}) {
            $pointer = $pointer->{$segment};
            next;
        }

        if( exists $pointer->{"*"}) {
            $pointer = $pointer->{"*"};
            $request->{route_params}{$pointer->{"<PARAM_NAME>"}} = $segment;
            next;
        }

        return undef unless exists $pointer->{"**"};
        $pointer = $pointer->{"**"};
        unshift @path_segments, $segment;
        $request->{route_params}{"<PATH>"} = join "/", @path_segments;
        @path_segments = () # captured the remaining path

    }

    return undef unless exists $pointer->{"<$method>"};
    return $pointer->{"<$method>"};
}

sub load_dbs {
    my ($self, $db_configs) = @_;

    for my $db_name (keys %$db_configs) {
        $self->_register_db($db_name, $db_configs->{$db_name});
    }
}

sub _register_db {
    my ($self, $name, $args) = @_;

    if (exists $self->{databases}{$name}) {
        die "A database with the same name is already registered: $name";
    }

    my $data_source = "dbi:$args->{driver}:database=$args->{database_name};host=$args->{hostname};port=$args->{port}";    
    $self->{databases}{$name} = DBIx::Connector->new($data_source, $args->{username}, $args->{password}, { RaiseError => 1, AutoCommit => 1 });
}

sub get_db {
    my ($self, $name) = @_;
    $name //= "main";

    unless (exists $self->{databases}{$name}) {
        die "A database with that name isn't registered: $name";
    }

    return $self->{databases}{$name};
}

sub to_psgi {
    my $self = shift;

    return sub {
        my $env = shift;
        my $request = SubPar::Request->new($env);

        my $handler = $self->_find_route($request);
        if(defined $handler) {
            my $response = $handler->($request);

            if(ref $response ne "SubPar::Response") {
                $response = SubPar::Response->status(200)
                    ->content_type(SubPar::ContentType::CT_JSON())
                    ->body($response);
            }

            return $response->to_psgi;
        }

        return SubPar::Response->status(404)
                    ->content_type(SubPar::ContentType::CT_JSON())
                    ->body({ error => "not found!"})
                    ->to_psgi;
    };
}

1;

__END__

=head1 NAME

SubPar::Server - Core HTTP server and router for SubPar::Web

=head1 SYNOPSIS

    use SubPar::Server;

    my $settings = do './settings.pl';

    my $server = SubPar::Server->new();
    $server->load_dbs($settings->{databases});
    $server->load_controllers();

    my $app = $server->to_psgi;

=head1 DESCRIPTION

SubPar::Server handles route registration, request dispatching and
database connection management. It is PSGI compatible and designed
to run behind Starman.

Handlers can return either a plain hashref (automatically wrapped
in a 200 JSON response) or a C<SubPar::Response> object for full
control over status code, headers and content type.

=head1 METHODS

=head2 new

    my $server = SubPar::Server->new();

Creates a new server instance with empty routes and databases.

=head2 load_controllers

    $server->load_controllers();

Auto-discovers and loads all C<.pm> files in the C<./Controller/>
directory. Each controller's C<register> method is called
automatically.

=head2 load_dbs

    $server->load_dbs($settings->{databases});

Registers all database connections from a hashref of database
configurations. Each key is the database name, each value is a
hashref with the following keys:

=over 4

=item C<driver> — DBI driver e.g. C<mysql>, C<Pg>, C<SQLite>

=item C<database_name> — database name

=item C<hostname> — database host

=item C<port> — database port

=item C<username> — database username

=item C<password> — database password

=back

=head2 get_db

    my $dbh = $server->get_db("main");
    my $dbh = $server->get_db;  # defaults to "main"

Returns a C<DBIx::Connector> handle for the named database.
Dies if the database was not registered.

=head2 to_psgi

    my $app = $server->to_psgi;

Returns a PSGI-compatible coderef. Pass this to Starman:

    starman --port 8080 app.psgi

Handlers returning a plain hashref are automatically wrapped in a
C<200 OK> JSON response. Handlers returning a C<SubPar::Response>
object are passed through as-is. Unknown routes return C<404>.

=head2 Routing

Routes are registered via C<SubPar::Controller>. The router supports:

=over 4

=item Static segments — C</users/profile>

=item Dynamic segments — C</users/:id> accessible via C<$req-E<gt>route_params('id')>

=item Catch-all wildcard — C</files/**> accessible via C<$req-E<gt>remaining_path>

=back

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut