package SubPar::Model;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless { %args }, $class;
    $self->validate(%args);
    return $self;
}

# a method that validates that all the fields were placed.
sub validate {
    my ($self, %args) = @_;
    my $fields = $self->fields;

    for my $field (keys %{$fields}) {
        next if $fields->{$field}{auto};

        if($fields->{$field}{required}) {
            die ref($self) . " missing required field: $field" unless defined $args{$field};
        }
    }
}

sub fields { 
    die ref(shift) . " must implement all of its fields";
}

sub get_hashref {
    my ($self) = @_;
    
    return $self;
}

sub to_string {
    my ($self) = @_;

    my $fields = join ", ", map{"$_=" . ($self->{$_} // 'undef')} sort ( keys %$self);

    return ref($self) . "[" . $fields . "]";
}

1;