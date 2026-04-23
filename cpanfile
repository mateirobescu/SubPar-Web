requires 'JSON::PP';
requires 'Starman';
requires 'DBI';
requires 'DBD::mysql';
requires 'URI';

on 'test' => sub {
    requires 'Test::More';
};