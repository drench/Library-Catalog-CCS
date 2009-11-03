package Library::Catalog::CCS;

our $VERSION = 0.01;

use strict;
use integer;
use warnings;

use Carp 'croak';
use DateTime ();
use Library::Catalog::CCS::Item ();
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

sub click_link {
    my $self = shift;

    my $link = $self->{mech}->find_link(@_);
    my $resp = $self->{mech}->get($link->[0]);
    croak($resp->as_string) if $resp->is_error;

    return $resp;
}

sub get_renewable_items {
    my $self = shift;

    $self->login();
    $self->click_link(text_regex => qr{\bMy\sAccount\b});
    my $resp = $self->click_link(text_regex => qr{\bRenew\sMy\sMaterials\b});

    return $self->parse_renewal_screen($resp);
}

sub parse_renewal_screen {
    my $self = shift;
    my $resp = shift;
    my $html = $resp->content();

    my $p = HTML::TokeParser->new(\$html);

    my @items;

    while (my $td = $p->get_token) {
        next if $td->[0] ne 'S';
        next if $td->[1] ne 'td';
        next if $td->[2]->{class} !~ /^itemlisting/;

        my $item = Library::Catalog::CCS::Item->new({parent => $self});
   
        my $input;
        while ($input = $p->get_token) {
            next if $input->[0] ne 'S';
            next if $input->[1] ne 'input';
            next if $input->[2]->{type} ne 'checkbox';
            $item->{checkbox} = $input->[2]->{name};
            last;
        }
   
        while (my $label = $p->get_token) {
            next if $label->[0] ne 'S';
            next if $label->[1] ne 'label';
            next if $label->[2]->{'for'} ne $input->[2]->{id};
            last;
        }
   
        my $lt = q{};

        while (my $lf = $p->get_token) {
            last if ($lf->[0] eq 'E') && ($lf->[1] eq 'label');

            if ($lf->[0] eq 'T') {
                $lt .= $lf->[1];
            }
        }
        for ($lt) {
            s/&nbsp;&nbsp;/: /gs;
            s/\s+/ /gs;
            s/^\s+//;
            s/\s+$//;
        }

        $item->{label} = $lt;

        while (my $dd = $p->get_token) {
            next if $dd->[0] ne 'S';
            next if $dd->[1] ne 'strong';
            last;
        }
   
        my $duedate = '';
        while (my $dd = $p->get_token) {
            last if ($dd->[0] eq 'E') && ($dd->[1] eq 'strong');
            next if $dd->[0] ne 'T';
            $duedate .= $dd->[1];
        }
   
        if ($duedate =~ m{(\d{1,2})/(\d{1,2})/(\d{4}),(\d\d):(\d\d)}) {
            $item->{duedate} = DateTime->new(
                year      => $3,
                month     => $1,
                day       => $2,
                hour      => $4,
                minute    => $5,
                second    => 0,
                time_zone => 'America/Chicago',
            );
        }
        else {
            croak("Bad duedate '$duedate'");
        }

        push @items, $item;

    }

    return @items;
}

1;
