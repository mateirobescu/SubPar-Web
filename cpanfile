requires 'JSON::PP';
requires 'Starman';
requires 'DBI';
requires 'URI';

on 'test' => sub {
    requires 'Test::More';
};