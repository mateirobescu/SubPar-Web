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

sub _register_method {
    my ($self, $method, $path, $sub) = @_;

    $self->{routes}{$path}{$method} = $sub;
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

        my $handler = $self->{routes}{$request->path}{$request->method};
        if(defined $handler) {
            my $response = $handler->($request);

            if(ref $response ne "SubPar::Response") {
                $response = SubPar::Response->new(
                    SubPar::Response::HTTP_200(),
                    SubPar::ContentType::CT_JSON(),
                    $response
                );
            }

            return $response->to_psgi;
        }

        return SubPar::Response->new(SubPar::Response::HTTP_404(), SubPar::ContentType::CT_JSON(), { error => "not found"})->to_psgi;

    };
}

1;