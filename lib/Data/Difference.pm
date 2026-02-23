package Data::Difference;
# ABSTRACT: Compare simple hierarchical data

use strict;
use warnings;
use base 'Exporter';

use Scalar::Util ();

our @EXPORT_OK = qw(data_diff);

sub data_diff {
  my ($left, $right) = @_;

  if (ref($left)) {
    if (my $sub = __PACKAGE__->can("_diff_" . ref($left))) {
      return $sub->($left, $right, {});
    }
    else {
      return {path => [], a => $left, b => $right};
    }
  }
  elsif (defined $left ? defined $right ? $left ne $right : 1 : defined $right) {
    return {path => [], a => $left, b => $right};
  }

  return;
}

sub _diff_HASH {
  my ($left, $right, $seen, @path) = @_;

  return {path => \@path, a => $left, b => $right} unless ref($left) eq ref($right);

  my $seen_key = Scalar::Util::refaddr($left) . ':' . Scalar::Util::refaddr($right);
  return if $seen->{$seen_key};
  local $seen->{$seen_key} = 1;

  my @diff;
  my %k;
  @k{keys %$left, keys %$right} = ();
  foreach my $k (sort keys %k) {
    if (!exists $left->{$k}) {
      push @diff, {path => [@path, $k], b => $right->{$k}};
    }
    elsif (!exists $right->{$k}) {
      push @diff, {path => [@path, $k], a => $left->{$k}};
    }
    elsif (ref($left->{$k})) {
      if (my $sub = __PACKAGE__->can("_diff_" . ref($left->{$k}))) {
        push @diff, $sub->($left->{$k}, $right->{$k}, $seen, @path, $k);
      }
      else {
        push @diff, {path => [@path, $k], a => $left->{$k}, b => $right->{$k}};
      }
    }
    elsif (defined $left->{$k} ? defined $right->{$k} ? $right->{$k} ne $left->{$k} : 1 : defined $right->{$k}) {
      push @diff, {path => [@path, $k], a => $left->{$k}, b => $right->{$k}};
    }
  }

  return @diff;
}

sub _diff_ARRAY {
  my ($left, $right, $seen, @path) = @_;
  return {path => \@path, a => $left, b => $right} unless ref($left) eq ref($right);

  my $seen_key = Scalar::Util::refaddr($left) . ':' . Scalar::Util::refaddr($right);
  return if $seen->{$seen_key};
  local $seen->{$seen_key} = 1;

  my @diff;
  my $n = $#$left > $#$right ? $#$left : $#$right;

  foreach my $i (0 .. $n) {
    if ($i > $#$left) {
      push @diff, {path => [@path, $i], b => $right->[$i]};
    }
    elsif ($i > $#$right) {
      push @diff, {path => [@path, $i], a => $left->[$i]};
    }
    elsif (ref($left->[$i])) {
      if (my $sub = __PACKAGE__->can("_diff_" . ref($left->[$i]))) {
        push @diff, $sub->($left->[$i], $right->[$i], $seen, @path, $i);
      }
      else {
        push @diff, {path => [@path, $i], a => $left->[$i], b => $right->[$i]};
      }
    }
    elsif (defined $left->[$i] ? defined $right->[$i] ? $right->[$i] ne $left->[$i] : 1 : defined $right->[$i]) {
      push @diff, {path => [@path, $i], a => $left->[$i], b => $right->[$i]};
    }
  }

  return @diff;
}

1;

__END__

=head1 SYNOPSYS

  use Data::Difference qw(data_diff);
  use Data::Dumper;

  my %from = (Q => 1, W => 2, E => 3, X => [1,2,3], Y=> [5,6]);
  my %to = (W => 4, E => 3, R => 5, => X => [1,2], Y => [5,7,9]);
  my @diff = data_diff(\%from, \%to);

  @diff = (
    # value $a->{Q} was deleted
    { 'a'    => 1, 'path' => ['Q'] },

    # value $b->{R} was added
    { 'b'    => 5, 'path' => ['R'] },

    # value $a->{W} changed
    { 'a'    => 2, 'b'    => 4, 'path' => ['W'] },

    # value $a->{X}[2] was deleted
    { 'a'    => 3, 'path' => ['X', 2] },

    # value $a->{Y}[1] was changed
    { 'a'    => 6, 'b'    => 7, 'path' => ['Y', 1] },

    # value $b->{Y}[2] was added
    { 'b'    => 9, 'path' => ['Y', 2] },
  );

=head1 DESCRIPTION

C<Data::Difference> will compare simple data structures returning a list of details about what was
added, removed or changed. It will currently handle SCALARs, HASH references and ARRAY references.

Each change is returned as a hash with the following element.

=over

=item path

path will be an ARRAY reference containing the hierarchical path to the value, each element in the array
will be either the key of a hash or the index on an array

=item a

If it exists it will contain the value from the first argument passed to C<data_diff>. If it
does not exist then this element did not exist in the first argument.

=item b

If it exists it will contain the value from the second argument passed to C<data_diff>. If it
does not exist then this element did not exist in the second argument.

=back

=head1 AUTHOR

Graham Barr C<< <gbarr@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2011 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
