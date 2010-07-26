# See bottom of file for license and copyright information
package Foswiki::Plugins::CalDAVPlugin::Core;

use strict;
use warnings;

use Cal::DAV;
use Foswiki::Time();
use DateTime::Format::ICal;

my %formats = (
    calendar => {
        event => '   * $day $month $year - $summary',
        range => '   * $day $month $year - $eday $emonth $eyear - $summary',
    },
    holidaylist => {
        event => '   * $day $month $year - $name - $summary - $icon',
        range => '   * $day $month $year - $eday $emonth $eyear - $name - $summary',
    },
   );

use constant TRACE => 1;

=begin TML

---++ StaticMethod CALDAV($session, $params, $topic, $web)

Macro handler, indirected via CalDAVPlugin.pm

Read CalDAV data from a remote server and generate output in a format
suitable for use by different plugins.

You can define an output format (using the 'target' parameter), or
select from a range of predefined formats. 'header', 'footer' and
'separator' have conventional interpretations, and all standard formatting
tokens are supported.

=cut

sub CALDAV {
    my($session, $params, $topic, $web) = @_;

    my $calendar = $params->{_DEFAULT};
    my $calspec;
    my $url;
    my $user;
    my $pass;
    if ($calendar) {
        # get from setup options
        $calspec = $Foswiki::cfg{Plugins}{CalDAVPlugin}{Calendars}->{$calendar};
        unless ($calspec) {
            return "<span class='foswikiAlert'>No such calendar '$calendar'</span>";
        }
    } else {
        $calspec = $params;
    }
    $url  = $calspec->{url};
    $user = $calspec->{user};
    $pass = $calspec->{pass};

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

    $params->{name} = $calendar unless defined $params->{name};
    $params->{name} = $params->{url} unless defined $params->{name};
    $params->{separator} = '$n()' unless defined $params->{separator};

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
                push(@events, " dtstart ".$event{start}) if (TRACE);
            } elsif ($k eq 'dtend') {
                $event{end} =
                  DateTime::Format::ICal->parse_datetime($p->value);
                push(@events, " dtend ".$event{end}) if (TRACE);
            } elsif ($k eq 'summary') {
                $event{summary} = $p->{value};
                push(@events, " summary ".$event{summary}) if (TRACE);
            } elsif ($k eq 'description') {
                $event{description} = $p->{value};
            } elsif ($k eq 'rrule') {
                push(@events, " rrule $p->{value}") if (TRACE);
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
            # Limit to the request range *or* $stopDays *or*
            # $stopCount repeats
            my $span = DateTime::Span->from_datetimes(
                start => $event{start} ||
                  DateTime->from_epoch(epoch => time),
                end => DateTime->from_epoch(
                    epoch => time+60*60*24*$stopDays ));
            $event{count} ||= $stopCount;
            $event{count} = $stopCount if ($event{count} > $stopCount);

            my $s = Foswiki::Time::parseTime($event{start});
            push(@events,
                 {
                     start => $s,
                     summary => $event{summary},
                     description => $event{description},
                 });
            $event{count}--;
            my $iter = $recur->iterator(span => $span);
            while ( $event{count} && (my $dt = $iter->next) ) {
                my $d = Foswiki::Time::parseTime($dt);
                next if $d == $s;
                push(@events,
                     {
                         start => $d,
                         summary => $event{summary},
                         description => $event{description},
                     });
                $event{count}--;
            }
        } else {
            push(@events,
                 {
                     start => Foswiki::Time::parseTime($event{start}),
                     end => (defined $event{end}) ?
                       Foswiki::Time::parseTime($event{end}) : undef,
                     summary => $event{summary},
                     description => $event{description},
                 });
        }
    }
    return _formatEvents(\@events, $params);
}

sub _formatEvents {
    my ($events, $params) = @_;

    my $format;
    my $target = $params->{target} || 'calendar';
    if ($target) {
        $format = $formats{$target} || $formats{calendar};
    }
    my $es = $params->{event};
    $es = $format->{event} unless defined $es;
    my $rs = $params->{range};
    $rs = $format->{range} unless defined $rs;
    my @r = map { _formatEvent($_, $params, $es, $rs) } @$events;
    return Foswiki::Func::decodeFormatTokens(join($params->{separator}, @r));
}

sub _formatEvent {
    my ($event, $params, $es, $rs) = @_;
    return $event unless ref($event);
    my $s = (defined $event->{end}) ? $rs : $es;
    $s = Foswiki::Time::formatTime($event->{start}, $s);
    if (defined $event->{end}) {
        $s =~ s/\$e(seco?n?d?s?|minu?t?e?s?|hour?s?|day|w(eek|day)|dow
                |mo(?:nt?h?)?|ye(?:ar)?)(\(\)|(?=\W|$))/\$$1/gx;
        $s = Foswiki::Time::formatTime($event->{end}, $s);
    }
    foreach my $f (keys %$event) {
        $s =~ s/\$$f(\(\)|(?=\W|$))/$event->{$f}/;
    }
    foreach my $f (keys %$params) {
        next if $f =~ /^_/;
        $s =~ s/\$$f(\(\)|(?=\W|$))/$params->{$f}/;
    }
    return $s;
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
