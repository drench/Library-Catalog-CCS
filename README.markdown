Library::Catalog::CCS
=====================

CCS is a consortium of libraries in the northern suburbs of Chicago.
http://www.ccs.nsls.lib.il.us/

This is a Perl 5 interface to the CCS library catalog system.
There is no API; it does everything through WWW::Mechanize.

Library::Catalog::CCS can tell you what items you have checked out
on your card and their due dates. It can also renew items that are
eligible for renewal.

It cannot yet search for items, determine their on-shelf status,
or place holds.

According to their blog[1], CCS is testing an updated version of
the catalog software. While the facade looks new, I don't see many changes
in the foundation. I had to make a minor change in the login() method in
my development branch, but that's it so far.

[1] http://ccsnews2.blogspot.com/2010/08/ccs-news-august-13-2010-from-computer.html
