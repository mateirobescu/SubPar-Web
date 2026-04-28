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