things_to_newline_on = [
  # 'BEGIN:VCALENDAR',
  'PRODID:',
  'VERSION:',
  'BEGIN:VEVENT',
  'DTSTAMP',
  'UID:',
  'DTSTART:',
  'DTEND:',
  'STATUS:',
  'CATEGORIES:',
  'SUMMARY:',
  'DESCRIPTION:',
  'LOCATION:',
  'END:VEVENT',
  'END:VCALENDAR'
]

print ARGF.read.gsub(Regexp.union(things_to_newline_on)){|m| "\n"+ m}
