# See bottom of file for license and copyright information
package Foswiki::Plugins::CalDAVPlugin;

=pod

---+ package Foswiki::Plugins::CalDAVPlugin

=cut

use strict;
use warnings;

use Foswiki::Func    ();

our $VERSION = '$Rev: 7888 $';
our $RELEASE = '1.001';
our $SHORTDESCRIPTION = 'Extract a list of events from a !CalDAV (iCal) server';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    # my ( $topic, $web, $user, $installWeb ) = @_;
    Foswiki::Func::registerTagHandler( 'CALDAV', \&_CALDAV );
    return 1;
}

sub _CALDAV {
    # my($session, $params, $topic, $web) = @_;

    require Foswiki::Plugins::CalDAVPlugin::Core;
#    *_CALDAV = \&Foswiki::Plugins::CalDAVPlugin::Core::CALDAV;
    return Foswiki::Plugins::CalDAVPlugin::Core::CALDAV(@_);
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
