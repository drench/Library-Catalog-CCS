package Library::Catalog::CCS;

use strict;
use integer;
use warnings;

our $VERSION = 0.02;

=head1

Library::Catalog::CCS - An interface to CCS library catalog systems

=head1 SYNOPSIS

  use Library::Catalog::CCS ();

  my $ccs = Library::Catalog::CCS->new({
    card => '21123000000000', password => 'ah7vauQu',
  });

  my $cutoff = DateTime->today() - DateTime::Duration->new(days => -1);

  foreach my $item ($ccs->get_renewable_items) {

    print $item->{duedate}->mdy('/'), ": $item->{label}\n";

    if ($item->{duedate} <= $cutoff) {
      my $result = $item->renew();
      if ($result) {
        print "\tRenewed; now due " . $result->{Due}->mdy('/') . "\n";
      }
      else {
        print "\tUnable to renew!\n";
      }
    }
  }

=head1 DESCRIPTION

=head1 USAGE

=cut

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

    $self->{mech}->cookie_jar({}); # clear cookies

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
        next if ! $td->[2]->{class};
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
   
        $item->{duedate} = parse_ccsdate($duedate)
            or croak("Bad duedate '$duedate'");

        push @items, $item;

    }

    return @items;
}

sub parse_ccsdate {
    my $dt = shift;
    if ($dt =~ m{(\d{1,2}) / (\d{1,2}) / (\d{4}) , (\d\d) : (\d\d)}x) {
        return DateTime->new(
            month     => $1,
            day       => $2,
            year      => $3,
            hour      => $4,
            minute    => $5,
            time_zone => 'America/Chicago',
        );
    }
    return;
}

1;

=head1 AUTHOR

Daniel Rench <citric@cubicone.tmetic.com>

=head1 COPYRIGHT

Copyright (c) 2009 Daniel Rench

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
