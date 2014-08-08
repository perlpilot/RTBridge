package RTBridge;
use Dancer2;
use MIME::Lite;
use Template;

our $VERSION = '0.1';
my $TEMPLATE = do { local $/; <DATA> };

post '/rt-check' => sub {
    my $json = params->{payload};
    my $perl = from_json $json;

    # Examine each commit, 
    # looking for references to RT in the commit messsage
    my %tickets;
    for my $commit (@{$perl->{commits}}) {
        if (my ($tick) = $commit->{message} =~ /\bRT\s*#?(\d+)/is) {
            push @{$tickets{$tick}}, $commit;
        }
    }

    # foreach RT ticket, generate an email
    my @email;
    for my $tick (keys %tickets) {
        my $tt = Template->new;
        my $message = join "-----\n", map { 
            $tt->process(\$TEMPLATE, $_, \my $template_copy); 
            $template_copy;
        } @{$tickets{$tick}};
        push @email, MIME::Lite->new(
            From    => 'perlpilot@gmail.com',
#            To      => 'perl6-bugs-followup@perl.org',
            To      => 'duff',
            Subject => "[RT #$tick] update",
            Type    => 'TEXT',
            Data    => $message,
        );
    }
    
    # send the email(s)
    for my $email (@email) {
#        $email->send('smtp', 'smtp.gmail.com', AuthUser => 'perlpilot', AuthPass => $pass);
    }

};

true;


__DATA__

[% message %]

Commit [% url %]
