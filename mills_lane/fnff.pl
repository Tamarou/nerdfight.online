#!/usr/bin/env perl
use 5.34.0;

use DBI;
use DBD::Pg qw(:pg_types);
use Getopt::Long;
use Mastodon::Client;
use Log::Any::Adapter ('Stderr');

GetOptions(
    "annual|a"       => \my $annual,
    "auth"           => \my $auth,
    "dry-run|n"      => \my $dry_run,
    "register|r"     => \my $reg,
    "test-message|t" => \my $test,
);

if ($reg) {
    my $client = Mastodon::Client->new(
        instance => $ENV{INSTANCE},
        name     => $ENV{USERNAME},
        scopes   => [qw(read write)],
    );

    $client->register( website => 'https://nerdfight.online', );
    say "Set the CLIENT_ID and CLIENT_SECRET in your environment";
    say "CLIENT_ID=" . $client->client_id;
    say "CLIENT_SECRET=" . $client->client_secret;
}

if ($auth) {
    my $client = Mastodon::Client->new(
        instance      => $ENV{INSTANCE},
        name          => $ENV{USERNAME},
        scopes        => [qw(read write)],
        client_id     => $ENV{CLIENT_ID},
        client_secret => $ENV{CLIENT_SECRET},
    );

    if ( $ENV{PASSWORD} ) {
        say $ENV{PASSWORD};
        $client->authorize(
            username => $ENV{USERNAME},
            password => $ENV{PASSWORD}
        );
        say $client->access_token;
    }
    elsif ( $ENV{ACCESS_CODE} ) {
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

my $post =
"This is a test. This station is conducting a test of the Emergency FNFF System. This is only a test";

unless ($test) {
    my $dbh = DBI->connect( "dbi:Pg:host=$ENV{PGHOST};dbname=$ENV{PGDATABASE}",
        $ENV{PGUSER}, $ENV{PGPASSWORD}, { AutoCommit => 0 } );

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

    $post = qq{
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
}
say STDERR $post;

exit if $dry_run;

say $ENV{CLIENT_ID};
say $ENV{CLIENT_SECRET};
say $ENV{ACCESS_TOKEN};

my $client = Mastodon::Client->new(
    instance       => $ENV{INSTANCE},
    name           => $ENV{USERNAME},
    scopes         => [qw(read write)],
    client_id      => $ENV{CLIENT_ID},
    client_secret  => $ENV{CLIENT_SECRET},
    access_token   => $ENV{ACCESS_TOKEN},
    coerce_entites => 1,
);

$client->post_status($post);
