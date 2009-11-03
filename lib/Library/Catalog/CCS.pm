package Library::Catalog::CCS;

our $VERSION = 0.01;

use strict;
use integer;
use warnings;

use Carp 'croak';
use DateTime ();
use WWW::Mechanize ();

our $BASEURL = 'http://64.107.155.140/cgi-bin/ibistro';

sub new {
    my $class = shift;
    my $self = shift || {};
    $self->{mech} = WWW::Mechanize->new();
    return bless $self, $class;
}

sub login {
    my $self = shift;

    if (! defined $self->{card}) {
        croak('No card number; cannot log in!');
    }

    $self->{card} =~ s/\D+//gs;
    if (! length $self->{card}) {
        croak('Invalid card number; cannot log in!');
    }

    $self->{password} = 'Patron' if ! defined $self->{password};

    my $resp = $self->{mech}->get($BASEURL);
    croak($resp->as_string) if $resp->is_error;

    $resp = $self->{mech}->submit_form(
        form_name => 'loginform',
        fields    => {
            user_id  => $self->{card},
            password => $self->{password},
        },
        button    => 'loginbutton',
    );
    croak($resp->as_string) if $resp->is_error;

    return $resp;
}

1;
