#!/usr/bin/env perl
use 5.34.0;
use local::lib q(local);

use Mastodon::Client;
use DBI;
use DBD::Pg qw(:pg_types);

my $dbh = DBI->connect("dbi:Pg:host=$ENV{DB_HOST};dbname=$ENV{DB_NAME}", $ENV{DB_USER}, $ENV{DB_PASS}, {AutoCommit => 0});

my $sql = q{
    SELECT users.nickname as nickname,
           COUNT(*) as vote_count,
           MIN(activities.inserted_at) as first_vote
    FROM  users
    INNER JOIN objects ON objects.data->>'actor' = users.ap_id
    INNER JOIN activities ON objects.data->>'id' = activities.data->>'object'
    WHERE activities.data['type'] = '"Like"'
      AND activities.local = true
      AND activities.inserted_at > now() - '1 week'::interval
    GROUP BY nickname
    ORDER BY vote_count DESC, first_vote ASC
    LIMIT 10
};

my $winners = $dbh->selectcol_arrayref($sql);
$dbh->disconnect;

my $list = join "\n", map qq{\@$_}, $winners->@*;

my $post = qq{
#FF #FakeNerdFightFriday

$list

LET'S GET IT ON!
};

say $post;
