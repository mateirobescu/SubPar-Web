package SubPar::Server;

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;
use DBI;

use SubPar::ContentType;
use SubPar::Response;

sub new {
    my ($class, $self) = @_;
    
    return bless { routes => {}, dbs => {} }, $class;
}

sub register_method {
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

        my $method = $env->{REQUEST_METHOD};
        my $path = $env->{PATH_INFO};

        my $body = '';
        if($env->{CONTENT_LENGTH}) {
            $env->{"psgi.input"}->read($body, $env->{CONTENT_LENGTH});
            $body = SubPar::ContentType::decode($env->{CONTENT_TYPE}, $body);
        }

        if(defined $self->{routes}{$path}{$method}) {
            my $response = $self->{routes}{$path}{$method}($body);
            return $response->to_psgi;
        }

        return SubPar::Response->new(SubPar::Response::HTTP_404(), SubPar::ContentType::CT_JSON(), { error => "not found"})->to_psgi;

    }
}

1;