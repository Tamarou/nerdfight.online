#!/usr/bin/env perl
use 5.40.0;

use DBI;
use DBD::Pg qw(:pg_types);
use Getopt::Long;
use Mastodon::Client;

GetOptions(
    "auth"      => \my $auth,
    "annual|a"  => \my $annual,
    "dry-run|n" => \my $dry_run,
    "deploy|d"  => \my $deploy,
);

if ($auth) {
    my $client = Mastodon::Client->new(
        instance      => $ENV{INSTANCE},
        name          => $ENV{USERNAME},
        client_id     => $ENV{CLIENT_ID},
        client_secret => $ENV{CLIENT_SECRET},
    );

    if ( $ENV{ACCESS_CODE} ) {
        say "saw access_code $ENV{ACCESS_CODE}";
        $client->authorize( access_code => $ENV{ACCESS_CODE} );
        say $client->access_token;
    }
    else {
        say "Authorization URL, please visit this in a browser";
        say $client->authorization_url();
    }

    exit;
}

my $dbh = DBI->connect(
    "dbi:Pg:host=$ENV{DB_HOST};port=$ENV{DB_PORT};dbname=$ENV{DB_NAME}",
    $ENV{DB_USER}, $ENV{DB_PASSWORD}, { AutoCommit => 0 } );

if ($deploy) {
    $dbh->do(
        qq{
            CREATE SCHEMA IF NOT EXISTS fnff;
            CREATE TABLE IF NOT EXISTS fnff.blocklist (
                nickname citext PRIMARY KEY,
                created_at timestamp with time zone DEFAULT now(),
            );
        }
    );
}

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
      AND users.nickname NOT IN (SELECT nickname FROM fnff.blocklist)
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

Here are this ${period}'s winners:

$list

LET'S GET IT ON!

As documented by \@fitzgepn\@mas.to on the hellsite,
\@jacobydave\@mastodon.xyz has [written about][1] his #ff script and the
curious phenomena of #fakeNerdFightFriday that sprang up from it.

If for some reason you're not interested in participating in FNFF, please let a
moderator know and we can add you to our blocklist.

[1]: https://jacoby.github.io/2019/07/05/the-social-experiment-of-followfriday.html
};

say STDERR $post;

exit if $dry_run;

my $client = Mastodon::Client->new(
    instance       => $ENV{INSTANCE},
    name           => $ENV{USERNAME},
    client_id      => $ENV{CLIENT_ID},
    client_secret  => $ENV{CLIENT_SECRET},
    access_token   => $ENV{ACCESS_TOKEN},
    coerce_entites => 1,
);

$client->post_status($post);
