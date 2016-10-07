# Dately
Stringy Date Magic

## Description
This is a poorly written module Perl 6 module for handling DateTime in a stringy context. Basically that means it's used for parsing and formatting.

It started out as a sketch for a module, and grew from there. I had plans to clean up the logic and make it a proper module on the ecosystem, but `$dayjob` and `$life` take up most of my spare time, and I don't see myself working on it anytime soon... So I'm putting it here so that other people may use it if they dare, or steal ideas from it if they so wish.

NOTE: Dately was a working title never intended to see release. If it ever saw the light of the ecosystem I probably would have called it `DateTime::Stringy` or something silly like `Medjool`.

## Synopsis
At it's heart, Dately is just a sub-class of `DateTime` that provides a few extra convenience methods for output.

```perl6
my $dt = Dately.new( '2016-10-05T15:43:21' );

say $dt.day-name; # Wednesday
say $dt.day-abbr; # Wed

say $dt.ymd;      # 2016-10-05
say $dt.ymd('_'); # 2016_10_05

say $dt.dmy;      # 05-10-2016
say $dt.dmy('/'); # 05-10-2016

say $dt.mdy;      # 10-05-2016
say $dt.mdy('|'); # 10|05|2016

say $dt.hms;      # 15:43:21
say $dt.hms(','); # 15,43,21
say $dt.time;     # 15:43:21    [ same as .hms() with no arg ]
say $dt.meridiem; # PM

say $dt.cdate;    # Wed Oct  5 15:43:21 2016

# These 2 are used for formatting later, but you can use them if you like

say $dt.yr;       # 16          [ 2-digit year ]
say $dt.clock;    # 3           [ hour as per clock face }]
```

The default date and time separators can be redefined.
```perl6
say $dt.date-seperator;    # '-'    [ returns current date-seperator ]
$dt.date-seperator('/');   # '/'    [ sets new seperator and returns it ]

say $dt.time-seperator;    # ':'    [ returns current time-seperator ]
$dt.time-seperator('_');   # '/'    [ sets new seperator and returns it ]

# Now when using methods like .ymd and .time will use the new seperators;
say $dt.ymd;      # 2016/10/05
say $dt.time      # 15_43_21
```

NOTE: This really should be implemented as a shared constant across all Dately objects, but it's not. Add that to the TODO.

But changing separators is boring anyway... What else can you change?
```perl6
# En Francais?

$dt.day-list(< lundi mardi mercredi jeudi vendredi samedi dimanche >);
$dt.month-list(< janvier février mars avril mai juin juillet août septembre octobre novembre décembre >);

say "Aujourd'hui c'est { $dt.day-name }, { $dt.day, $dt.month-name, $dt.year }.";>)>)
# OUTPUT: Aujourd'hui c'est mercredi, 5 octobre 2016.
```

Again, this is cool, but semi-useless without being constant across all Dately objects.

## Formatting
Ok, so you've got a Dately object and you want to output it in your format of choice. With the handy new methods above, you could probably build it yourself, but Dately also has support for `strftime` style format strings.

```perl6
say $dt.format('%a %b %e %T %Y');
# OUTPUT: Wed Oct  5 15:43:21 2016
```
Ok, I could have just done that with `.cdate` so lets do something different

```perl6
say $dt.format('%a %B %u, %r %Y');
# OUTPUT: Wed October 3, 3:15:43 PM 2016
```
All the main format tokens work. The following are not supported: -
  * Timezone: `%Z`
  * Modifiers: `%E` and `%O`
  * locale-specific ones: `%x` and `%X`
  * The weird ones: `%W` and `%U` ( aka, first-sunday-of-year-that-starts-with-four-day-week )

Again this is not an officially released module, so I make no guarantees I've implemented any of these formatters correctly. That said, I did refer to `man strftime` and Perl5's `Time::Piece->strftime` quite a bit so it should be mostly fairly good-ish.

## Parsing
Ahh, date parsing. Everyones favourite stress-relief past-time. Parsing dates is hard, and I probably made a mistake somewhere, but here goes.

As with formatting, `strptime` format strings are supported.

```perl6
my $dtp = Dately.parse('Wed Oct  5 15:43:21 2016', '%a %b %e %T %Y');
say $dtp; # 2016-10-05T15:43:21Z    [ Dately object ]
```
I've already covered format strings, and you probably know how to use them, so I'll stop there.

As a final note on format parsing, I don't think there is any module currently in the ecosystem that does `strftime` style parsing. I think it's mainly because it's a pain to do right... Which is to say, I probably have missed a few edge cases... Which is to say, my implementation is probably not a reference you want to copy.

## Magic
Now for a little silliness. Often the dates I'm working with are in a set format, so I don't want to bother with format strings most of the time, so `.parse` has an "auto-parse" multi that takes no format string; It will attempt to parse your string just by looking at it! Please stop furrowing your brow, I'm aware how stupid this is.

As an Australian, I only partially recognise the American silliness of the MDY format as provided in the `.mdy` method. As far as auto-parsing is concerned, it will always presume DMY on ambiguous dates. I guess this could also be edited to appeal to American tastes, or even set via variable or locale setting, but I probably won't be making changes to this thing.

In any case, here is a sample of formats that auto-parse correctly.

```perl6
say Dately.parse( '2015-11-12T09:34:57' );                 # OUTPUT: 2015-11-12T09:34:57Z
say Dately.parse( 'Thu Nov  5 14:16:23 AEDT 2015' );       # OUTPUT: 2015-11-05T14:16:23Z
say Dately.parse( 'Thu, 12 Nov 2015 02:40:08 GMT' );       # OUTPUT: 2015-11-12T02:40:08Z
say Dately.parse( 'Wednesday, 19-Nov-75 16:14:55 EST' );   # OUTPUT: 1975-11-19T16:14:55Z
say Dately.parse( '1:32pm on the 4th of June 2007' );      # OUTPUT: 2007-06-04T13:32:00Z
say Dately.parse( 'Monday, June 15, 2009 1:45 PM' );       # OUTPUT: 2009-06-15T13:45:00Z
say Dately.parse( 'March 7 2009 7:30pm EST' );             # OUTPUT: 2009-03-07T19:30:00Z
say Dately.parse( '10/12/2015 3:26 PM' );                  # OUTPUT: 2015-12-10T15:26:00Z
say Dately.parse( '8/19/16 4:00 PM' );                     # OUTPUT: 2016-08-19T16:00:00Z
say Dately.parse( '08/06/2009' );                          # OUTPUT: 2009-06-08T00:00:00Z
```

The grammar is a true work of horror. I strip out any punctuation that isn't a colon, as well as common date/time joining words (< at of on the >) and then construct rules from vague tokens, ie. The `<month>` token will correctly identify March from `any(< 3 03 mar Mar march March>`.

It could be extended to support more formats easily, or made a bit smarter with stricter tokens, or the auto-parse multi could really be removed entirely, because you could just use the `strptime` style format strings. I mainly added it for `all(< experimental learning fun >)` purposes.

