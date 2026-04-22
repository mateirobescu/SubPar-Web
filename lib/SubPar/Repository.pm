package SubPar::Repository;

use strict;
use warnings;

sub new {
    my ($class, $dbh) = @_;

    return bless { dbh => $dbh }, $class;   
}

sub save {
    my ($self, $model) = @_;

    my $model_fields = $model->get_hashref();

    my @field_names = keys %$model_fields;
    my @field_values = values %$model_fields;
    my $field_names_str = join ", ", @field_names;

    my $nr_of_fields = @field_names;
    my $placeholders = join ", ", (('?')) x $nr_of_fields;

    $self->{dbh}->prepare(
        "INSERT INTO " . $self->table . " ($field_names_str) VALUES ($placeholders)"
    )->execute(
        @field_values
    );
}

sub table {
    die ref(shift) . " must implement table().";
}

1;