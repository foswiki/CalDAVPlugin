# See bottom of file for license and copyright information
package Foswiki::Configure::Checkers::Plugins::CalDAVPlugin::Calendars;

use strict;
use warnings;
use locale;

use Foswiki::Configure::Checker ();
our @ISA = ('Foswiki::Configure::Checker');

sub check {
    my $this = shift;

    eval "require Data::ICal";
    return $@ if $@;

    local $/ = undef;
    my $data = <DATA>;

    $data = substr(lc('x').$data, 1);
    die "WANK" unless Scalar::Util::tainted($data);
    eval {
        Data::ICal->new(data => $data);
    };
    if ($@) {
        if ($@ =~ /Insecure dependency in eval while running with -T switch at (\S+)/) {
            my $copy = $1;
            my $e = <<MESSAGE;
<div>
Data::ICal is broken. This problem has been reported to the CPAN
maintainer, and awaits a fix. There may already be a new version
on CPAN, or you can patch it locally if you have the skills:
<pre>
patch -p0 <<'HERE'
--- $copy    2010-07-01 16:51:12.000000000 +0100
+++ $copy    2010-07-01 17:01:55.000000000 +0100
MESSAGE
        $e .= <<'MESSAGE';
@@ -487,5 +487,6 @@
     die "Can't parse VALARM with action $action"
         unless exists $_action_map{$action};
-    my $alarm_class = "Data::ICal::Entry::Alarm::" . $_action_map{$action};
+    my $x = $_action_map{$action};
+    my $alarm_class = "Data::ICal::Entry::Alarm::" . $x;
     eval "require $alarm_class";
     die "Failed to require $alarm_class : $@" if $@;
HERE
</pre>
MESSAGE
            return $this->ERROR($e);
        }
        return $this->ERROR($@);
    }
}

1;
__DATA__
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
METHOD:PUBLISH
PRODID:-//Apple Inc.//iCal 3.0//EN
VERSION:2.0
X-WR-CALNAME:Home
X-WR-RELCALID:0F57501D-E9CE-48C9-9681-7ECA18D2C057
X-WR-TIMEZONE:Europe/London
BEGIN:VTIMEZONE
TZID:Europe/London
BEGIN:DAYLIGHT
DTSTART:19810329T010000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
TZNAME:BST
TZOFFSETFROM:+0000
TZOFFSETTO:+0100
END:DAYLIGHT
BEGIN:STANDARD
DTSTART:19961027T020000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
TZNAME:GMT
TZOFFSETFROM:+0100
TZOFFSETTO:+0000
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
CREATED:20100701T071114Z
DTEND;TZID=Europe/London:20100703T074500
DTSTAMP:20100701T073836Z
DTSTART;TZID=Europe/London:20100703T073000
SEQUENCE:3
SUMMARY:Alarmed
TRANSP:OPAQUE
UID:2E1C1DE7-580E-4784-92A9-85ED2F778F67
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:Event reminder
TRIGGER:-PT15M
X-WR-ALARMUID:0EC58885-5380-41DB-B4EE-CCE2C86AEE6D
END:VALARM
END:VEVENT
END:VCALENDAR
