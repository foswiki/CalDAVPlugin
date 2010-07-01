# See bottom of file for license and copyright information
package Foswiki::Plugins::CalDAVPlugin;

=pod

---+ package Foswiki::Plugins::CalDAVPlugin

When developing a plugin it is important to remember that
Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See %SYSTEMWEB%.InstalledPlugins for error messages.

__NOTE:__ Foswiki:Development.StepByStepRenderingOrder helps you decide which
rendering handler to use. When writing handlers, keep in mind that these may
be invoked on included topics. For example, if a plugin generates links to the
current topic, these need to be generated before the =afterCommonTagsHandler=
is run. After that point in the rendering loop we have lost the information
that the text had been included from another topic.

__NOTE:__ Not all handlers (and not all parameters passed to handlers) are
available with all versions of Foswiki. Where a handler has been added
(or deprecated) the POD comment will indicate this with a "Since" line
e.g. *Since:* Foswiki::Plugins::VERSION 1.1

See http://foswiki.org/Download/ReleaseDates for a breakdown of release
versions.

=cut

use strict;
use warnings;

use Foswiki::Func    ();

our $VERSION = '$Rev: 7888 $';
our $RELEASE = '1.1.1';
our $SHORTDESCRIPTION = 'Extract a list of events from a CalDAV (iCal) server';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    Foswiki::Func::registerTagHandler( 'CALDAV', \&_CALDAV );

    return 1;
}

sub _CALDAV {
    my($session, $params, $theTopic, $theWeb) = @_;

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
