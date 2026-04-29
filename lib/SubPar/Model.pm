package SubPar::Model;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my ($class, %field_values) = @_;
    my $self = bless { %field_values }, $class;
    $self->_validate(%field_values);


    return $self;
}

# a method that validates that all the fields were placed.
sub _validate {
    my ($self, %field_values) = @_;
    my @fields = @{$self->fields};

    for (my $i = 0; $i < @fields; $i += 2) {
        my $field_name = $fields[$i];
        my $meta = $fields[$i + 1];
        
        if (not exists $field_values{$field_name}) {
            next if $meta->{auto};
            croak ref($self) . " missing required field: $field_name" if $meta->{required};
        }

        if(exists $meta->{validation}) {
            my $valid = $meta->{validation}->($field_values{$field_name});
            croak ref($self) . " failed field validation: $field_name" unless $valid;
        }
    }
}

sub fields { 
    croak ref(shift) . " must implement all of its fields as an arrayref";
}

sub ordered_fields {
    my ($self) = @_;

    my @ordered = ();
    my @fields = @{$self->fields};

    for(my $i = 0; $i < @fields; $i += 2) {
        push @ordered, $fields[$i];
    }

    return \@ordered;
}

sub to_hashref {
    my ($self) = @_;
    
    return { %$self };
}

sub TO_JSON {
    my ($self) = @_;
    return $self->to_hashref;
}

sub to_string {
    my ($self) = @_;

    my $fields = join ", ", map{"$_=" . ($self->{$_} // 'undef')} @{$self->ordered_fields};

    return ref($self) . "[" . $fields . "]";
}

1;

1;

__END__

=head1 NAME

SubPar::Model - Base class for SubPar models

=head1 SYNOPSIS

    package Model::Person;
    use parent 'SubPar::Model';

    sub fields {
        return [
            id         => { auto => 1, pk => 1 },
            first_name => { required => 1 },
            last_name  => { required => 1 },
            email      => { required => 1, validation => sub { $_[0] =~ /\@/ } },
            age        => { required => 1, validation => sub { $_[0] > 0 } },
        ];
    }

    1;

    # usage
    my $person = Model::Person->new(
        first_name => 'John',
        last_name  => 'Doe',
        email      => 'john@example.com',
        age        => 30,
    );

=head1 DESCRIPTION

SubPar::Model is the base class for all models. It provides field
declaration, validation, and serialization. Subclass it and implement
C<fields> to define your model's structure.

=head1 METHODS

=head2 new

    my $model = Model::Person->new(%field_values);

Creates a new model instance and validates the provided field values.
Dies with a validation error if required fields are missing or
validation functions fail.

=head2 fields

    sub fields {
        return [
            field_name => { required => 1, auto => 0, validation => sub { ... } },
        ];
    }

Override in subclass. Returns an arrayref of field name and metadata
pairs in declaration order. Field metadata options:

=over 4

=item C<required> — field must be present when creating the model

=item C<auto> — field is auto generated e.g. database primary key, skipped during validation

=item C<validation> — coderef that receives the field value and returns true/false

=back

=head2 ordered_fields

    my $order = $model->ordered_fields;

Returns an arrayref of field names in declaration order.

=head2 to_hashref

    my $hash = $model->to_hashref;

Returns the model's field values as a plain hashref. Only includes
fields that were set — auto fields like C<id> are not included unless
explicitly provided.

=head2 TO_JSON

Called automatically by C<JSON::PP> when serializing the model.
Delegates to C<to_hashref>.

=head2 to_string

    print $model->to_string;
    # Model::Person[email=john@example.com, first_name=John, last_name=Doe]

Returns a human readable string representation of the model with
fields in declaration order.

=head1 AUTHOR

Matei-Gabriel Robescu

=head1 LICENSE

MIT

=cut