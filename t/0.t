# vim: se ft=perl :

use Test::More tests => 2;

use_ok('Library::Catalog::CCS');

if ($ENV{CARD}) {
    $ENV{PASS} = 'Patron' if ! defined $ENV{PASS};

    my $ccs = Library::Catalog::CCS->new({
        card => $ENV{CARD}, password => $ENV{PASS}
    });

    ok($ccs->login()->is_success);
}
else {
    warn "Not testing login\n";
    ok(1);
}
