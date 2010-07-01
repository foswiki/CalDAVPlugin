# See bottom of file for license and copyright information
package Foswiki::Plugins::CalDAVPlugin::Core;

use Cal::DAV;
use Foswiki::Time();
use DateTime::Format::ICal;

# Target formats
# dd MMM yyyy - description
#   * 09 Dec 2002 - Expo
# dd MMM yyyy - dd MMM yyyy - description
#   * 02 Feb 2002 - 04 Feb 2002 - Vacation
# dd MMM - description
#   * 05 Jun - Every 5th of June
# w DDD MMM - description
#   * 2 Tue Mar - Every 2nd Tuesday of March
# rrule: FREQ=MONTHLY
# L DDD MMM - description
#   * L Mon May - The last Monday of May
# rrule: FREQ=MONTHLY
# A dd MMM yyyy - description
#   * A 20 Jul 1969 - First moon landing
# FREQ=YEARLY
# w DDD - description
#   * 1 Fri - Every 1st Friday of the month
# FREQ=MONTHLY,BYDAY=FR
# L DDD - description
#   * L Mon - The last Monday of each month
# dd - description 	
#   * 14 - The 14th of every month
# E DDD - description
#   * E Wed - Every Wednesday
# E DDD dd MMM yyyy - description
#   * E Wed 27 Jan 2005 - Every Wednesday Starting 27 Jan 2005
# E DDD dd MMM yyyy - dd MMM yyyy - description
#   * E Wed 1 Jan 2005 - 27 Jan 2005 - Every Wednesday from 1 Jan 2005 through 27 Jan 2005 (inclusive)
# En dd MMM yyyy - description
#   * E3 02 Dec 2002 - Every three days starting 02 Dec 2002
# En dd MMM yyyy - dd MMM yyyy - description
#   * E3 12 Apr 2005 - 31 Dec 2005 - Every three days from 12 Apr 2005 through 31 Dec 2005 (inclusive) 

sub CALDAV {
    my($session, $params, $topic, $web) = @_;

    my $calendar = $params->{_DEFAULT};
    my $url;
    my $user;
    my $pass;
    if ($calendar) {
        # get from setup options
        my $calspec = $Foswiki::cfg{Plugins}{CalDAVPlugin}{Calendars}->{$calendar};
        unless ($calspec) {
            return "<span class='foswikiAlert'>No such calendar '$calendar'</span>";
        }
    } else {
        $url  = $params->{url};
        $user = $params->{user};
        $pass = $params->{pass};
    }
    unless ($url) {
        return "<span class='foswikiAlert'>No url given</span>";
    }
    unless (defined $user && defined $pass) {
        return "<span class='foswikiAlert'>user and pass must be given</span>";
    }

    my $cal;
    eval {
       $cal = Cal::DAV->new( user => $user, pass => $pass, url => $url);
    };
    unless ($cal) {
        print STDERR "Cal::DAV: $@\n";
        return "<span class='foswikiAlert'>Calendar could not be opened</span>";
    }

    my $stop = $params->{stop};
    $stop = "50,365" unless defined($stop);
    unless($stop =~ /^(\d+), *(\d+)$/) {
        return "<span class='foswikiAlert'>Invalid stop=\"$stop\"</span>";
    }
    my ( $stopCount, $stopDays ) = ( $1, $2 );

    my @events;
    foreach my $e ( @{$cal->entries()}) {
        next unless $e->ical_entry_type() eq 'VEVENT';
        my %event;
        my $props = $e->properties();
        while (my ($k, $e) = each %$props) {
            my $p = $e->[0];
            if ($k eq 'dtstart') {
                $event{dtstart} = $p->{value};
                $event{start} =
                  DateTime::Format::ICal->parse_datetime($p->value);
                push(@events, "# dtstart ".$event{start});
            } elsif ($k eq 'dtend') {
                $event{end} =
                  DateTime::Format::ICal->parse_datetime($p->value);
                push(@events, "# dtend ".$event{end});
            } elsif ($k eq 'summary') {
                $event{description} = $p->{value};
                $event{description} =~ s/\n/<br>/gs;
            } elsif ($k eq 'rrule') {
                push(@events, "# rrule $p->{value}");
                $event{recurrence} = $p->{value};
            }
        }
        if ($event{recurrence}) {
            # count= is broken in DateTime::Event::ICal
            if ($event{recurrence} =~ s/;?count=(\d+);?/;/i) {
                $event{count} = $1;
            }
            my $recur = DateTime::Format::ICal->parse_recurrence(
                recurrence => $event{recurrence},
                dtstart => $event{start});
            # Limit to the request range *or* $stopDays *or* $stopCount repeats
            my $span = DateTime::Span->from_datetimes(
                start => $event{start} ||
                  DateTime->from_epoch(epoch => time),
                end => DateTime->from_epoch(
                    epoch => time+60*60*24*$stopDays ));
            $event{count} ||= $stopCount;
            $event{count} = $stopCount if ($event{count} > $stopCount);

            push(@events, "   * ".Foswiki::Time::formatTime(
                Foswiki::Time::parseTime($event{start}))
                   . ' - '.$event{description});
            $event{count}--;
            my $iter = $recur->iterator(span => $span);
            while ( $event{count} && (my $dt = $iter->next) ) {
                push(@events, "   * " . Foswiki::Time::formatTime(
                    Foswiki::Time::parseTime($dt))
                   . ' - '.$event{description});
                $event{count}--;
            }
        } else {
            my $evs = Foswiki::Time::formatTime(
                    Foswiki::Time::parseTime($event{start}));
            if (defined $event{end}) {
                $evs .= ' - '.Foswiki::Time::formatTime(
                    Foswiki::Time::parseTime($event{end}));
            }
            $evs .= ' - '.$event{description};
            push(@events, "   * $evs");
        }
    }
    return "\n".join("\n", @events)."\n";
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
