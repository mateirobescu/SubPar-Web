requires 'JSON::PP';
requires 'Starman';
requires 'DBI';
requires 'URI';
requires 'DBIx::Connector';

on 'test' => sub {
    requires 'Test::More';
};