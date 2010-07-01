#---+ Extensions
#---++ CalDAVPlugin
# **PERL**
# Set of calendars that can be accessed using shortcuts frm the CALDAV macro.
# Each calendar specification must include a user, password and url.
$Foswiki::cfg{Plugins}{CalDAVPlugin}{Calendars} = {
   home => {
      url => 'http://simian:x@192.168.1.12/caldav.php/simian/home/Home.ics',
      user => 'simian',
      pass => 'x'
   },
};
