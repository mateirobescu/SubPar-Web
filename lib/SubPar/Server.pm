package SubPar::Server;

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;
use DBI;

use ContentType;
use Response;

sub new {
    my ($class, $self) = @_;
    
    return bless { routes => {}, dbs => {} }, $class;
}

sub register_method {
    my ($self, $method, $path, $sub) = @_;

    $self->{routes}{$path}{$method} = $sub;
}

sub send_response {
    my ($self, $client, $body, $content_type) = @_;

    my $response;
    if($content_type eq "application/json") {
        $response = encode_json($body);
    }

    print $client "HTTP/1.1 200 OK\r\n";
    print $client "Content-Type: $content_type\r\n";
    print $client "Content-Length: " . length($response) . "\r\n";
    print $client "\r\n";
    print $client $response;
}

sub read_body {
    my ($self, $client, $request) = @_;

    my ($content_type) = $request =~ /Content-Type:\s+([a-zA-Z\/]+)/;
    my ($length) = $request =~ /Content-Length:\s+([0-9]+)/;
    my $body = '';
    read($client, $body, $length) if $length;

    $body = ContentType::decode($content_type, $body);

    return $body;
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
            $body = ContentType::decode($env->{CONTENT_TYPE}, $body);
        }

        if(defined $self->{routes}{$path}{$method}) {
            my $response = $self->{routes}{$path}{$method}($body);
            return $response->to_psgi;
        }

        return Response->new(Response::HTTP_404, ContentType::CT_JSON, { error => "not found"})->to_psgi;

    }
}

1;