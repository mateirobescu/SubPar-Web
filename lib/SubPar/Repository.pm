package SubPar::Repository;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my ($class, $dbh) = @_;

    return bless { dbh => $dbh }, $class;   
}

sub save {
    my ($self, $model) = @_;

    my $model_fields = $model->to_hashref();

    my @field_names = keys %$model_fields;
    my @field_values = @$model_fields{@field_names};
    my $field_names_str = join ", ", @field_names;

    my $nr_of_fields = @field_names;
    my $placeholders = join ", ", (('?')) x $nr_of_fields;

    my $result = $self->get_db->run( sub {
        my $sth = $_->prepare("INSERT INTO " . $self->table . " ($field_names_str) VALUES ($placeholders)");

        return $sth->execute(@field_values);
    });

    return $result;
}

sub get_db {
    my ($self) = @_;

    return $self->{dbh};
}

sub table {
    croak ref(shift) . " must implement table().";
}

1;

__END__

=head1 NAME

SubPar::Repository - Base class for SubPar repositories

=head1 SYNOPSIS

    package Repository::PersonRepository;
    use parent 'SubPar::Repository';

    sub table { 'persons' }

    sub get_all {
        my ($self) = @_;
        return $self->get_db->run(sub {
            my $sth = $_->prepare("SELECT * FROM " . $self->table);
            $sth->execute();
            return [ map { Model::Person->new(%$_) } @{$sth->fetchall_arrayref({})} ];
        });
    }

    1;

    # usage
    my $repo = Repository::PersonRepository->new($server->get_db("main"));
    my $persons = $repo->get_all;
    $repo->save($person);

=head1 DESCRIPTION

SubPar::Repository is the base class for all repositories. It provides
a database connection and a generic C<save> method. Subclass it,
implement C<table>, and add your own query methods.

=head1 METHODS

=head2 new

    my $repo = Repository::PersonRepository->new($dbh);

Creates a new repository instance with the given C<DBIx::Connector>
connection handle.

=head2 table

    sub table { 'persons' }

Override in subclass. Returns the database table name this repository
operates on. Dies if not implemented.

=head2 save

    $repo->save($model);

Inserts a model into the database. Field names and values are derived
from C<$model-E<gt>to_hashref>. Only fields present in the hashref
are inserted except for auto fields that will be generated if they are not present in the model.

=head2 get_db

    my $dbh = $self->get_db;

Returns the C<DBIx::Connector> connection handle. Use this inside
your repository methods to run queries:

    $self->get_db->run(sub {
        $_->prepare("SELECT * FROM " . $self->table)->execute();
    });

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut