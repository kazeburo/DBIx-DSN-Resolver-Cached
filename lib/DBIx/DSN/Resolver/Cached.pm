package DBIx::DSN::Resolver::Cached;

use strict;
use warnings;
use parent qw/DBIx::DSN::Resolver/;
use Cache::Memory::Simple;

our $VERSION = '0.01';
my %RR;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $ttl = exists $args{ttl} ? delete $args{ttl} : 5;
    my $negative_ttl = exists $args{negative_ttl} ? delete $args{negative_ttl} : 1;
    my $cache = exists $args{cache} ? delete $args{cache} : Cache::Memory::Simple->new;
    my $resolver = sub {
        my $host = shift;
        if ( my $cached = $cache->get($host) ) {
            return if @$cached == 0;
            if ( exists $RR{$host} ) {
                $RR{$host}++;
                $RR{$host} = 0 if $RR{$host} >= scalar @$cached;
            } else {
                $RR{$host} = 1;
            }
            return $cached->[$RR{$host}]
        }
        my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname($host);
        if ( ! defined $name ) {
            $cache->set($host,[],$negative_ttl);
            return;
        }
        my @ipaddr = map { Socket::inet_ntoa($_) } @addrs;
        $cache->set($host,\@ipaddr,$negative_ttl);
        return $ipaddr[0];
    };
    $class->SUPER::new(
        resolver => $resolver
    );
}

1;

__END__

=head1 NAME

DBIx::DSN::Resolver::Cached - Cached resolver for DBIx::DSN::Resolver

=head1 SYNOPSIS

  use 5.10;
  use DBIx::DSN::Resolver::Cached;

  sub connect_db {
      state $resolver = DBIx::DSN::Resolver::Cached->new(
          ttl => 30,
          negative_ttl => 5,
      );
      my $dsn = $resolver->resolv('dbi:mysql:database=mytbl;host=myserver.example');
      DBI->connect($dsn,'user','password');
  }

=head1 DESCRIPTION

DBIx::DSN::Resolver::Cached is extension module of DBIx::DSN::Resolver.
This module allows CACHE resolver response, useful for reduce load of DNS

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
