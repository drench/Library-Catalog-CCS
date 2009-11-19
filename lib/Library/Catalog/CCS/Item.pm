package Library::Catalog::CCS::Item;

use strict;
use integer;
use warnings;

use Carp qw(carp croak);

BEGIN {
    no strict 'refs';
    *{'parse_ccsdate'} = \&{'Library::Catalog::CCS::parse_ccsdate'};
}

sub new {
    my $class = shift;
    my $arg = shift || {};
    return bless $arg, $class;
}

sub parse_renewal_result {
    my $self = shift;
    my $resp = shift;
    my $html = $resp->content();

    my $p = HTML::TokeParser->new(\$html);

    # find "Renewal Results: 1 item was renewed"
    while (my $t = $p->get_token) {
        next unless ($t->[0] eq 'S') && ($t->[1] eq 'strong');

        my $txt = '';
        while ($t = $p->get_token) {
            last if ($t->[0] eq 'E') && ($t->[1] eq 'strong');
            next unless $t->[0] eq 'T';
            $txt .= $t->[1];
        }

        for ($txt) { s/[\r\n]+/ /gs; s/\s+/ /gs; s/^\s+//; s/\s+$//; }

# FIX: make sure $txt really contains what we expected
        carp($txt);
        last;
    }

    # find new due date and number of times renewed:
    while (my $t = $p->get_token) {
        next unless ($t->[0] eq 'S') && ($t->[1] eq 'dd');

        my %info;
        my $k;

        while ($t = $p->get_token) {
            last if ($t->[1] eq 'E') && ($t->[1] eq 'dd');
            next unless $t->[0] eq 'T';
            next if $t->[1] !~ /\S/;

            if ($t->[1] =~ /\b(.+):\s/) {
                $k = $1;
            }
            elsif (defined $k) {
                $info{$k} = parse_ccsdate($t->[1]) || $t->[1];
                $k = undef;
            }
        }

        # %info should contain:
        #  "Date renewed"
        #  "Times renewed"
        #  "Due"

        return \%info;
    }

    return;
}

sub renew {
    my $self = shift;

    $self->{parent}->login();
    $self->{parent}->click_link(text_regex => qr{\bMy\sAccount\b});
    $self->{parent}->click_link(text_regex => qr{\bRenew\sMy\sMaterials\b});

    my $resp = $self->{parent}{mech}->submit_form(
        form_name => 'renewitems',
        fields    => {
            selection_type    => 'selected', # as opposed to "all"
            $self->{checkbox} => 'on',
            user_id           => $self->{parent}{card},
        },
    );
    croak($resp->as_string) if $resp->is_error;
    return $self->parse_renewal_result($resp);
}

1;
