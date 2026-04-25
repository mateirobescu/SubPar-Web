package SubPar::Server;

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;
use DBI;

use SubPar::ContentType;
use SubPar::Response;
use SubPar::Request;

sub new {
    my ($class, $self) = @_;
    
    return bless { routes => {}, dbs => {} }, $class;
}

use Data::Dumper;

sub _register_route {
    my ($self, $method, $path, $sub) = @_;

    $path =~ s/^\///;
    $path =~ s/\/$//;
    my @path_segments = split /\//, $path;

    my $pointer = $self->{routes};
    for my $segment (@path_segments) {
        if(substr($segment, 0, 1) eq ":") {
            my $param_name = substr($segment, 1);
            die "Another similar dynamic route already exists: $method - $path" if $pointer->{"*"}{"<PARAM_NAME>"} eq $param_name;

            $pointer = $pointer->{"*"};
            $pointer->{"<PARAM_NAME>"} = $param_name;
        }
        else {
            $pointer->{$segment} = {};
            $pointer = $pointer->{$segment};
        }
    }

    die "Route already exists: $method - $path" if defined $pointer->{"<$method>"};
    $pointer->{"<$method>"} = $sub;

    # $self->{routes}{$path}{$method} = $sub;
}

sub _find_route {
    my ($self, $request) = @_;
    my ($method, $path) = ($request->method, $request->path);

    $path =~ s/^\///;
    $path =~ s/\/$//;
    my @path_segments = split /\//, $path;

    my $pointer = $self->{routes};
     for my $segment (@path_segments) {
        unless (defined $pointer->{$segment}) {
            return undef unless defined $pointer->{"*"};

            $pointer = $pointer->{"*"};
            $request->{route_parameters}{$pointer->{"<PARAM_NAME>"}} = $segment;
        }
        else {
            $pointer = $pointer->{$segment};
        }
    }

    return undef unless defined $pointer->{"<$method>"};
    return $pointer->{"<$method>"};
}

sub register_db {
    my ($self, $name, $args) = @_;

    if (exists $self->{dbs}{$name}) {
        die "A database with the same name is already registered: $name";
    }

    my $data_source = "dbi:$args->{driver}:database=$args->{database_name};host=$args->{hostname};port=$args->{port}";    
    $self->{dbs}{$name} = DBI->connect($data_source, $args->{username}, $args->{password});
}

sub get_db {
    my ($self, $name) = @_;
    $name //= "main";

    unless (exists $self->{dbs}{$name}) {
        die "A database with that name isn't registered: $name";
    }

    return $self->{dbs}{$name};
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