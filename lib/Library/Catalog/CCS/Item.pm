package Library::Catalog::CCS::Item;

use strict;
use integer;
use warnings;

sub new {
    my $class = shift;
    my $arg = shift || {};
    return bless $arg, $class;
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
    return $resp;
}

1;
