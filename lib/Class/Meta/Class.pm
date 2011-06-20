package Class::Meta::Class;

=head1 NAME

Class::Meta::Class - Class::Meta class introspection

=head1 SYNOPSIS

  # Assuming MyApp::Thingy was generated by Class::Meta.
  my $class = MyApp::Thingy->my_class;
  my $thingy = MyApp::Thingy->new;

  print "Examining object of class ", $class->package, $/;

  print "\nConstructors:\n";
  for my $ctor ($class->constructors) {
      print "  o ", $ctor->name, $/;
  }

  print "\nAttributes:\n";
  for my $attr ($class->attributes) {
      print "  o ", $attr->name, " => ", $attr->get($thingy) $/;
  }

  print "\nMethods:\n";
  for my $meth ($class->methods) {
      print "  o ", $meth->name, $/;
  }

=head1 DESCRIPTION

Object of this class describe classes created by Class::Meta. They contain
everything you need to know about a class to be able to put objects of that
class to good use. In addition to retrieving meta data about the class itself,
you can retrieve objects that describe the constructors, attributes, and
methods of the class. See C<Class::Meta|Class::Meta> for a fuller description
of the utility of the Class::Meta suite of modules.

Class::Meta::Class objects are created by Class::Meta; they are never
instantiated directly in client code. To access the class object for a
Class::Meta-generated class, simply call its C<my_class()> method.

At this point, those attributes tend to be database-specific. Once other types
of data stores are added (XML, LDAP, etc.), other attributes may be added to
allow their schemas to be built, as well.

=cut

##############################################################################
# Dependencies                                                               #
##############################################################################
use strict;
use Class::ISA ();
use Class::Meta;
use Class::Meta::Attribute;
use Class::Meta::Method;

##############################################################################
# Package Globals                                                            #
##############################################################################
our $VERSION = '0.64';
our @CARP_NOT = qw(Class::Meta);

=head1 INTERFACE

=head2 Constructors

=head3 new

A protected method for constructing a Class::Meta::Class object. Do not call
this method directly; Call the L<C<new()>|Class::Meta/new"> constructor on a
Class::Meta object, instead. A Class::Meta::Class object will be constructed
by default, and can always be retrieved via the C<my_class()> method of the
class for which it was constructed.

=cut

##############################################################################

sub new {
    my ($pkg, $spec) = @_;
    # Check to make sure that only Class::Meta or a subclass is
    # constructing a Class::Meta::Class object.
    my $caller = caller;
    Class::Meta->handle_error("Package '$caller' cannot create $pkg objects")
      unless UNIVERSAL::isa($caller, 'Class::Meta')
      || UNIVERSAL::isa($caller, __PACKAGE__);

    # Set the name to be the same as the key by default.
    $spec->{name} ||= join ' ', map { ucfirst } split '_', $spec->{key};

    # Set the abstract attribute.
    $spec->{abstract} = $spec->{abstract} ? 1 : 0;

    # Set the trusted attribute.
    $spec->{trusted} = exists $spec->{trust}
      ? ref $spec->{trust} ? delete $spec->{trust} : [ delete $spec->{trust} ]
      : [];

    # Okay, create the class object.
    my $self = bless $spec, ref $pkg || $pkg;
}

##############################################################################
# Instance Methods
##############################################################################

=head2 Instance Methods

=head3 package

  my $pkg = $class->package;

Returns the name of the package that the Class::Meta::Class object describes.

=head3 key

  my $key = $class->key;

Returns the key name that uniquely identifies the class across the
application. The key name may simply be the same as the package name.

=head3 name

  my $name = $class->name;

Returns the name of the the class. This should generally be a descriptive
name, rather than a package name.

=head3 desc

  my $desc = $class->desc;

Returns a description of the class.

=head3 abstract

  my $abstract = $class->abstract;

Returns true if the class is an abstract class, and false if it is not.

=head3 default_type

  my $default_type = $class->default_type;

The data type used for attributes of the class that were added with no
explicit types.

=head3 trusted

  my @trusted = $class->trusted;
  my $trusted = $class->trusted;

In an array context, returns a list of class names that this class trusts.
Returns the same list in an array reference in a scalar context.

=cut

sub package  { $_[0]->{package}  }
sub key      { $_[0]->{key}      }
sub name     { $_[0]->{name}     }
sub desc     { $_[0]->{desc}     }
sub abstract { $_[0]->{abstract} }
sub default_type { $_[0]->{default_type} }
sub trusted  { wantarray ? @{ $_[0]->{trusted} } : [ @{ $_[0]->{trusted} } ] }

##############################################################################

=head3 is_a

  if ($class->is_a('MyApp::Base')) {
      print "All your base are belong to us\n";
  }

This method returns true if the object or package name passed as an argument
is an instance of the class described by the Class::Meta::Class object or one
of its subclasses. Functionally equivalent to
C<< $class->package->isa($pkg) >>, but more efficient.

=cut

sub is_a { UNIVERSAL::isa($_[0]->{package}, $_[1]) }

##############################################################################
# Accessors to get at the constructor, attribute, and method objects.
##############################################################################

=head3 constructors

  my @constructors = $class->constructors;
  my $ctor = $class->constructors($ctor_name);
  @constructors = $class->constructors(@ctor_names);

Provides access to the Class::Meta::Constructor objects that describe the
constructors for the class. When called with no arguments, it returns all of
the constructor objects. When called with a single argument, it returns the
constructor object for the constructor with the specified name. When called
with a list of arguments, returns all of the constructor objects with the
specified names.

=cut

##############################################################################

=head3 attributes

  my @attributes = $class->attributes;
  my $attr = $class->attributes($attr_name);
  @attributes = $class->attributes(@attr_names);

Provides access to the Class::Meta::Attribute objects that describe the
attributes for the class. When called with no arguments, it returns all of the
attribute objects. When called with a single argument, it returns the
attribute object for the attribute with the specified name. When called with a
list of arguments, returns all of the attribute objects with the specified
names.

=cut

##############################################################################

=head3 methods

  my @methods = $class->methods;
  my $meth = $class->methods($meth_name);
  @methods = $class->methods(@meth_names);

Provides access to the Class::Meta::Method objects that describe the methods
for the class. When called with no arguments, it returns all of the method
objects. When called with a single argument, it returns the method object for
the method with the specified name. When called with a list of arguments,
returns all of the method objects with the specified names.

=cut

for ([qw(attributes attr)], [qw(methods meth)], [qw(constructors ctor)]) {
    my ($meth, $key) = @$_;
    no strict 'refs';
    *{$meth} = sub {
        my $self = shift;
        my $objs = $self->{"${key}s"};
        # Who's talking to us?
        my $caller = caller;
        for (my $i = 1; UNIVERSAL::isa($caller, __PACKAGE__); $i++) {
            $caller = caller($i);
        }
        # XXX Do we want to make these additive instead of discreet, so that
        # a class can get both protected and trusted attributes, for example?
        my $list = do {
            if (@_) {
                # Explicit list requested.
                \@_;
            } elsif ($caller eq $self->{package}) {
                # List of protected interface objects.
                $self->{"priv_$key\_ord"} || [];
            } elsif (UNIVERSAL::isa($caller, $self->{package})) {
                # List of protected interface objects.
                $self->{"prot_$key\_ord"} || [];
            } elsif (_trusted($self, $caller)) {
                # List of trusted interface objects.
                $self->{"trst_$key\_ord"} || [];
            } else {
                # List of public interface objects.
                $self->{"$key\_ord"} || [];
            }
        };
        return @$list == 1 ? $objs->{$list->[0]} : @{$objs}{@$list};
    };
}

##############################################################################

=head3 parents

  my @parents = $class->parents;

Returns a list of Class::Meta::Class objects representing all of the
Class::Meta-built parent classes of a class.

=cut

sub parents {
    my $self = shift;
    return map { $_->my_class } grep { UNIVERSAL::can($_, 'my_class') }
      Class::ISA::super_path($self->package);
}

##############################################################################

=head3 handle_error

  $class->handle_error($error)

Handles Class::Meta-related errors using either the error handler specified
when the Class::Meta::Class object was created or the default error handler at
the time the Class::Meta::Class object was created.

=cut

sub handle_error {
    my $code = shift->{error_handler};
    $code->(join '', @_)
}

##############################################################################

=head3 build

  $class->build($classes);

This is a protected method, designed to be called only by the Class::Meta
class or a subclass of Class::Meta. It copies the attribute, constructor, and
method objects from all of the parent classes of the class object so that they
will be readily available from the C<attributes()>, C<constructors()>, and
C<methods()> methods. Its sole argument is a reference to the hash of all
Class::Meta::Class objects (keyed off their package names) stored by
Class::Meta.

Although you should never call this method directly, subclasses of
Class::Meta::Class may need to override its behavior.

=cut

sub build {
    my ($self, $classes) = @_;

    # Check to make sure that only Class::Meta or a subclass is building
    # attribute accessors.
    my $caller = caller;
    $self->handle_error("Package '$caller' cannot call " . ref($self)
                        . "->build")
      unless UNIVERSAL::isa($caller, 'Class::Meta')
      || UNIVERSAL::isa($caller, __PACKAGE__);

    # Copy attributes again to make sure that overridden attributes
    # truly override.
    $self->_inherit($classes, qw(ctor meth attr));
}

##############################################################################
# Private Methods.
##############################################################################

sub _inherit {
    my $self = shift;
    my $classes = shift;

    # Get a list of all of the parent classes.
    my $package = $self->package;
    my @classes = reverse Class::ISA::self_and_super_path($package);

    # Hrm, how can I avoid iterating over the classes a second time?
    my @trusted;
    for my $super (@classes) {
        push @trusted, @{$classes->{$super}{trusted}}
          if $classes->{$super}{trusted};
    }
    $self->{trusted} = \@trusted if @trusted;

    # For each metadata class, copy the parents' objects.
    for my $key (@_) {
        my (@lookup, @all, @ord, @prot, @trst, @priv, %sall, %sord, %sprot, %strst);
        for my $super (@classes) {
            my $class = $classes->{$super};
            if (my $things = $class->{$key . 's'}) {
                push @lookup, %{ $things };

                if (my $ord = $class->{"$key\_ord"}) {
                    push @ord, grep { not $sord{$_}++ }   @{ $ord} ;
                }

                if (my $prot = $class->{"prot_$key\_ord"}) {
                    push @prot, grep { not $sprot{$_}++ } @{ $prot };
                }

                if (my $trust = $class->{"trst_$key\_ord"}) {
                    push @trst, grep { not $strst{$_}++ } @{ $trust };
                }

                if (my $all = $class->{"all_$key\_ord"}) {
                    for my $name (@{ $all }) {
                        next if $sall{$name}++;
                        push @all, $name;
                        my $view  = $things->{$name}->view;
                        push @priv, $name if $super eq $package
                            || $view == Class::Meta::PUBLIC
                            || $view == Class::Meta::PROTECTED
                            || _trusted($class, $package);
                    }
                }
            }
        }

        $self->{"${key}s"}        = { @lookup } if @lookup;
        $self->{"$key\_ord"}      = \@ord       if @ord;
        $self->{"all_$key\_ord"}  = \@all       if @all;
        $self->{"prot_$key\_ord"} = \@prot      if @prot;
        $self->{"trst_$key\_ord"} = \@trst      if @trst;
        $self->{"priv_$key\_ord"} = \@priv      if @priv;
    }


    return $self;
}

sub _trusted {
    my ($self, $caller) = @_;
    my $trusted = $self->{trusted} or return;
    for my $pkg (@{$trusted}) {
        return 1 if UNIVERSAL::isa($caller, $pkg);
    }
    return;
}

1;
__END__

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/class-meta/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/class-meta/issues/> or by sending mail to
L<bug-Class-Meta.cpan.org|mailto:bug-Class-Meta.cpan.org>.

Patches against Class::Meta are welcome. Please send bug reports to
<bug-class-meta@rt.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 SEE ALSO

Other classes of interest within the Class::Meta distribution include:

=over 4

=item L<Class::Meta|Class::Meta>

=item L<Class::Meta::Constructor|Class::Meta::Constructor>

=item L<Class::Meta::Attribute|Class::Meta::Attribute>

=item L<Class::Meta::Method|Class::Meta::Method>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
