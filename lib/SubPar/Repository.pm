package SubPar::Repository;

use strict;
use warnings;

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
    die ref(shift) . " must implement table().";
}

1;