package Class::Meta::AccessorBuilder;

# $Id: AccessorBuilder.pm,v 1.8 2004/01/09 04:14:46 david Exp $

=head1 NAME

Class::Meta::AccessorBuilder - Perl style accessor generation

=head1 SYNOPSIS

  package MyApp::TypeDef;

  use strict;
  use Class::Meta::Type;
  use IO::Socket;

  my $type = Class::Meta::Type->add( key     => 'io_socket',
                                     builder => 'default',
                                     desc    => 'IO::Socket object',
                                     name    => 'IO::Socket Object' );

=head1 DESCRIPTION

This module provides the default accessor builder for Class::Meta. It builds
standard Perl-style accessors. For example, an attribute named "io_socket"
would have a single accessor method, C<io_socket>.

=head2 Accessors

Class::Meta::AccessorBuilder create three different types of accessors:
read-only, write-only, and read/write. The type of accessor created depends on
the value of the C<authz> attribute of the Class::Meta::Attribute for which
the accessor is being created.

For example, if the C<authz> is Class::Meta::RDWR, then the method will be
able to both read and write the attribute.

  my $value = $obj->io_socket;
  $obj->io_socket($value);

If the value of C<authz> is Class::Meta::READ, then the method will not
be able to change the value of the attribute:

  my $value = $obj->io_socket;
  $obj->io_socket($value); # Has no effect.

And finally, if the value of C<authz> is Class::Meta::WRITE, then the method
will not return the value of the attribute (why anyone would want this is
beyond me, but I provide for the sake of completeness):

  $obj->io_socket($value);
  my $value = $obj->io_socket;  # Always returns undef.

=head2 Data Type Validation

Class::Meta::AccessorBuilder uses all of the validation checks passed to it to
validate new values before assigning them to an attribute. It also checks to
see if the attribute is required, and if so, adds a check to ensure that its
value is never undefined. It does not currently check to ensure that private
and protected methods are used only in their appropriate contexts, but may do
so in a future release.

=cut

use strict;
use Class::Meta;
our $VERSION = "0.11";

sub build_attr_get {
    UNIVERSAL::can($_[0]->package, $_[0]->name);
}

*build_attr_set = \&build_attr_get;

my $croak = sub {
    require Carp;
    our @CARP_NOT = qw(Class::Meta::Attribute);
    Carp::croak(@_);
};

my $req_chk = sub {
    $croak->("Attribute must be defined") unless defined $_[0];
};

sub build {
    my ($pkg, $attr, $create, @checks) = @_;
    unshift @checks, $req_chk if $attr->required;
    my $name = $attr->name;

    # XXX Do I need to add code to check the caller and throw an exception for
    # private and protected methods?

    no strict 'refs';
    if ($create == Class::Meta::GET) {
        # Create GET accessor.
        *{"${pkg}::$name"} = sub { $_[0]->{$name} };

    } elsif ($create == Class::Meta::SET) {
        # Create SET accessor.
        if (@checks) {
            *{"${pkg}::$name"} = sub {
                # Check the value passed in.
                $_->($_[1]) for @checks;
                # Assign the value.
                $_[0]->{$name} = $_[1];
                return;
            };
        } else {
            *{"${pkg}::$name"} = sub {
                # Assign the value.
                $_[0]->{$name} = $_[1];
                return;
            };
        }

    } elsif ($create == Class::Meta::GETSET) {
        # Create GETSET accessor(s).
        if (@checks) {
            *{"${pkg}::$name"} = sub {
                my $self = shift;
                return $self->{$name} unless @_;
                # Check the value passed in.
                $_->($_[0]) for @checks;
                # Assign the value.
                return $self->{$name} = $_[0];
            };
        } else {
            *{"${pkg}::$name"} = sub {
                my $self = shift;
                return $self->{$name} unless @_;
                # Assign the value.
                return $self->{$name} = shift;
            };
        }
    } else {
        # Well, nothing I guess.
    }
}

1;
__END__

=head1 AUTHOR

David Wheeler <david@kineticode.com>

=head1 BUGS

Please report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Meta>.

=head1 SEE ALSO

=over 4

=item L<Class::Meta|Class::Meta>

This class contains most of the documentation you need to get started with
Class::Meta.

=item L<Class::Meta::AccessorBuilder::Affordance|Class::Meta::AccessorBuilder::Affordance>

This module generates affordance style accessors.

=item L<Class::Meta::Type|Class::Meta::Type>

This class manages the creation of data types.

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

This class manages Class::Meta class attributes, most of which will have
generated accessors.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004, David Wheeler. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
