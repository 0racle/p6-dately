#!/usr/bin/env perl6

use lib 'lib';
use Dately;

use Test;

my @tests = (
    [ '2015-11-12T09:34:57',                '2015-11-12T09:34:57Z' ],
    [ 'Thu Nov  5 14:16:23 AEDT 2015',      '2015-11-05T14:16:23Z' ],
    [ 'Thu, 12 Nov 2015 02:40:08 GMT',      '2015-11-12T02:40:08Z' ],
    [ 'Wednesday, 19-Nov-75 16:14:55 EST',  '1975-11-19T16:14:55Z' ],
    [ '1:32pm on the 4th of June 2007',     '2007-06-04T13:32:00Z' ],
    [ 'Monday, June 15, 2009 1:45 PM',      '2009-06-15T13:45:00Z' ],
    [ 'March 7 2009 7:30pm EST',            '2009-03-07T19:30:00Z' ],
    [ '10/12/2015 3:26 PM',                 '2015-12-10T15:26:00Z' ],
    [ '8/19/16 4:00 PM',                    '2016-08-19T16:00:00Z' ],
    [ '08/06/2009',                         '2009-06-08T00:00:00Z' ],
);

plan @tests.elems;

for @tests -> @test {
    my ($string, $result) = @test;
    ok( Dately.parse($string) eq $result, "Parsed '$string'" );
}

