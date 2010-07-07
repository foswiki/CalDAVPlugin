#---+ Extensions
#---++ CalDAVPlugin
# **PERL**
# Set of calendars that can be accessed using shortcuts form the CALDAV macro.
# Each calendar specification must include a user, password and url.
$Foswiki::cfg{Plugins}{CalDAVPlugin}{Calendars} = {
   example => {
      url => 'http://example.com/caldav.php/example',
      user => 'example',
      pass => 'example'
   },
};
