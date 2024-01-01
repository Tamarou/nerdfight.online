#!/usr/bin/env perl
use 5.34.0;

use DBI;
use DBD::Pg qw(:pg_types);
use Getopt::Long;
use Mastodon::Client;

GetOptions(
    "annual|a" => \my $annual,
    "dry-run|n" => \my $dry_run,
);

my $dbh = DBI->connect("dbi:Pg:host=$ENV{PGHOST};dbname=$ENV{PGDATABASE}", $ENV{PGUSER}, $ENV{PGPASSWORD}, {AutoCommit => 0});

my $period = $annual ? 'year' : 'week';

my $sql = qq{
    SELECT users.nickname as nickname,
           COUNT(*) as vote_count,
           MIN(activities.inserted_at) as first_vote
    FROM  users
    INNER JOIN objects ON objects.data->>'actor' = users.ap_id
    INNER JOIN activities ON objects.data->>'id' = activities.data->>'object'
    WHERE activities.data['type'] = '"Like"'
      AND activities.local = true
      AND activities.inserted_at > now() - '1 $period'::interval
    GROUP BY nickname
    ORDER BY vote_count DESC, first_vote ASC
    LIMIT 10
};

say STDERR $sql;

my $winners = $dbh->selectcol_arrayref($sql);
$dbh->disconnect;

my $list = join "\n", map qq{\@$_}, $winners->@*;

my $post = qq{
#FF #FakeNerdFightFriday

As \@fitzgepn\@mas.to explained on [the birdsite][1]:

\@jacobydave\@mastodon.xyz has [written about][2] his #ff script and the
curious phenomena of #fakeNerdFightFriday that sprang up from it.

[1]: https://twitter.com/fitzgepn/status/1297712297595400192
[2]: https://jacoby.github.io/2019/07/05/the-social-experiment-of-followfriday.html

Here are this ${period}'s winners:

$list

LET'S GET IT ON!
};

say STDERR $post;

exit if $dry_run;

my $client = Mastodon::Client->new(
    instance => $ENV{INSTANCE},
    name => $ENV{USERNAME},
    client_id => $ENV{CLIENT_ID},
    client_secret => $ENV{CLIENT_SECRET},
    access_token => $ENV{ACCESS_TOKEN},,
    coerce_entites => 1,
);

$client->post_status($post);
