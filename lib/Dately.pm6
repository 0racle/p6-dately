unit module Dately;

class Dately is DateTime is export {

    my @MONTH_LIST = <
        January  February  March
        April    May       June
        July     August    September
        October  November  December
    >;

    my @DAY_LIST = <
        Monday Tuesday Wednesday Thursday Friday Saturday Sunday
    >;

    state %DAY_LIST   = @DAY_LIST.map({ ++$ => $_ });
    state %DAY_ABBR   = @DAY_LIST.map({ ++$ => $_.substr(0, 3) });

    state %MONTH_LIST = @MONTH_LIST.map({ ++$ => $_ });
    state %MONTH_ABBR = @MONTH_LIST.map({ ++$ => $_.substr(0, 3) });

    state %N_MONTH    = @MONTH_LIST.map({ substr($_, 0, 3).lc => ++$ }); # Used for auto-parse

    state $DATE_SEP   = '-';
    state $TIME_SEP   = ':';

    method day-list (@days where *.elems == 7) {
        %DAY_LIST = @days.map({ ++$ => $_ });
    }

    method month-list (@months where *.elems == 12) {
        %MONTH_LIST = @months.map({ ++$ => $_ });
        %N_MONTH = @MONTH_LIST.map({ substr($_, 0, 3).lc => ++$ });
    }
    method date-seperator($s = $DATE_SEP) { $DATE_SEP = $s }
    method time-seperator($s = $DATE_SEP) { $TIME_SEP = $s }

    method day-name   { %DAY_LIST{ $.day-of-week }; }
    method day-abbr   { %DAY_ABBR{ $.day-of-week }; }
    method month-name { %MONTH_LIST{ $.month }; }
    method month-abbr { %MONTH_ABBR{ $.month }; }

    method ymd ($s = $DATE_SEP) { sprintf("%d$s%02d$s%02d", $.year,  $.month, $.day); }
    method dmy ($s = $DATE_SEP) { sprintf("%02d$s%02d$s%d", $.day,   $.month, $.year); }
    method mdy ($s = $DATE_SEP) { sprintf("%02d$s%02d$s%d", $.month, $.day,   $.year); }
    method hms ($s = $TIME_SEP) { sprintf("%02d$s%02d$s%02d", $.hour, $.minute, $.second); }

    method time { $.hms(); }
    method meridiem { $.hour < 12 ?? 'AM' !! 'PM' }
    method clock { $.hour == 0 ?? ~12 !! $.hour > 12 ?? $.hour - 12 !! $.hour; }
    method yr { $.year < 2000 ?? $.year - 1900 !! $.year - ($.year - 500).round(1000); }
    method cdate { sprintf('%s %s % 2s %s %s', $.day-abbr, $.month-abbr, $.day, $.hms, $.year); }

    method format(Str $fmt) returns Str {
        my %F =(
            a => $.day-abbr,
            A => $.day-name,
            b => $.month-abbr,
            B => $.month-name,
            c => self.cdate,
            C => sprintf('%02d', $.year ÷ 100),
            d => sprintf('%02d', $.day),
            D => $.mdy('/'),
            e => sprintf('% 2d', $.day),
            E => '', # Modifier - NOT INPLEMENTED
            F => $.ymd,
            h => $.month-abbr,
            H => sprintf('%02d', $.hour),
            I => self.clock,
            m => sprintf('%02d', $.month),
            M => sprintf('%02d', $.minute),
            n => "\n",
            O => '', # Modifier - NOT INPLEMENTED
            p => self.meridiem,
            P => self.meridiem.lc,
            r => sprintf('%s:%02d:%02d %s', self.clock, $.hour, $.minute, $.meridiem),
            R => sprintf('%02d:%02d', $.hour, $.minute),
            s => $.posix,
            S => sprintf('%02d', $.second),
            t => "\t",
            T => $.hms,
            u => $.day-of-week,
            U => '', # Week Number << 1st Sun week of year with 4 days) : NOT IMPLEMENTED
            V => $.week[*-1],
            w => $.day-of-week == 7 ?? 0 !! $.day-of-week - 1,
            W => '', # Week Number << 1st M week of year ) : NOT IMPLEMENTED
            x => $.ymd, # Truly, should be date in locale w/o time : KIND OF IMPLEMENTED
            X => $.hms, # Truly, should be time in locale w/o date : KIND OF IMPLEMENTED
            y => $.yr,
            Y => $.year,
            z => ( $.offset > 0 ?? '+' !! '' ) ~ $.offset / 36,
            Z => '', # TZ Name - NOT IMPLEMENTED
          '+' => self.cdate,
          '%' => '%',
        );

        my $str = $fmt;
        for $fmt ~~ m:g/'%'./ -> $m {
            if %F{ $m.substr(1) } -> $s {
                $str.=subst($m, $s);
            }
        }
        return ~$str;
    }

    my token twelve     { ( \d\d? ) <?{ 0 < $0 <= 12 }> }
    my token thirtyone  { ( \d\d? ) <?{ 0 < $0 <= 31 }> }
    my token twentyfour { ( \d\d )  <?{ $0 < 24 }> }
    my token sixty      { ( \d\d )  <?{ $0 < 60 }> }
    my token suffix     { :i st | nd | rd | th }
    my token meridiem   { :i [ AM | PM ] }
    my token hour       { <twelve> | <twentyfour> }
    my token minute     { <sixty> }
    my token second     { <sixty> }
    my token day        { <thirtyone><suffix>?  }
    my token year       { \d ** 1..4 }
    my token zone       { <[A..Z]> ** 1..4 || <[-+]> \d ** 1..4 }
    my token time       {
        <hour> ':' <minute> [':' <second>]? [\s* <meridiem>]? [\s* <zone>]?
    }
    my token weekday {
        ( <:Letter>+ ) <?{
            $0.lc eq any (%DAY_LIST, %DAY_ABBR).flatmap(&values).map(&lc)
        }>
    }
    my token month {
        <twelve>
        ||
        ( <:Letter>+ ) <?{
            $0.lc eq any (%MONTH_LIST, %MONTH_ABBR).flatmap(&values).map(&lc)
        }>
    }

    grammar Dately::Grammar {
        rule  TOP        {
            ^^ [ <dt=iso8601> | <dt=asctime> | <dt=unix> | <dt=dately> ] $$
        }
        rule  iso8601    { <year> <month> <day>.?<time> }
        rule  asctime    { <month> <day> <time> <year> }
        rule  unix       { <weekday> <month> <day> <time> <year> }
        rule  dately     {
            <weekday>?  [ <day> <month> <year> | <month> <day> <year> ] <time>?
            ||
            <time>? [ <day> <month> <year> | <month> <day> <year> ]
        } 
    }

    multi method parse(Str $string) {
        my $stripped = $string.subst(/:i <:P - [:]>|<<[at|of|on|the]>>/, ' ', :g);
        Dately::Grammar.parse( $stripped );
        if $/ { return $.convert($/) }
        return fail;
    }

    multi method parse(Str $string, Str $fmt) {
        my %P = (
            a => '<weekday>',  A => '<weekday>',  b => '<month>',   B => '<month>',
            c => '<unix>',     C => '<year>',
            d => '<day>',      D => '<month><[/]><day><[/]><year>',
            e => '<day>',      E => '', # Modifier - Not implemented
            f => '<year><[-]><month><[-]><day>',  h => '<month>',   H => '<hour>',
            I => '<hour>',     m => '<month>',    M => '<minute>',  n => '<ws>',
            p => '<meridiem>', P => '<meridiem>',
            T => '<time>',
            Y => '<year>',
        );

        my @tokens;
        for $fmt ~~ m:g/'%'./ -> $m {
            @tokens.push: %P{ $m.substr(1) };
        }
        use MONKEY-SEE-NO-EVAL; # EVAL is safe, only EVALing internal strings
        my $rx = EVAL '/' ~ @tokens.join('\s+') ~ '/';
        if $string ~~ $rx {
            return $.convert($/);
        }
        return fail;
    }

    method convert(Match $/ is rw) {
        if $<dt> { $/ = $<dt>; }

        my $year  = $<year>  ?? ~$<year>  !! Nil; 
        my $month = $<month> ?? ~$<month> !! Nil;  
        my $day   = $<day>   ?? ~$<day>   !! Nil; 

        my $hour   = $<time><hour>   ?? $<time><hour>   !! 0;
        my $minute = $<time><minute> ?? $<time><minute> !! 0;
        my $second = $<time><second> ?? $<time><second> !! 0;
        my $zone   = $<zone>         ?? $<zone>         !! 0;

        if $year.chars == 2 {
            my $now = DateTime.now;
            $year = $year >= 50 - $now.year.substr(2, 2)
              ?? $year + 1900 !! $year + 2000;
        }

        if $month ~~ Str {
            $month = %N_MONTH{ $month.substr(0, 3).lc } || $month
        }

        if $<day><suffix> {
            $day = $day.substr(0, $day.chars - 2);
        }

        if $<time><meridiem> -> $m {
            if $m.uc eq 'PM' && $hour < 12 {
                $hour += 12;
            }
            elsif $m.uc eq 'PM' && $hour == 12 {
                $hour = 0;
            }
        }

        return Dately.new(
            year   => +$year,
            month  => +$month,
            day    => +$day,
            hour   => +$hour,
            minute => +$minute,
            second => +$second,
        );
    }
}
