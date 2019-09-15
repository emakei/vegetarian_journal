use v6;
use LibCurl::Easy;
use Gumbo;
use JSON::Fast;

my $domain = 'https://vegjournal.com';
my @records;

my $main-page = LibCurl::Easy.new(URL => "$domain/issues/").perform.content(enc => 'utf-8');
my @navigation-block = parse-html($main-page, :TAG<div>, :class<navigation-pages>);

die "Navigation pages count = $(@navigation-block.end+1)" if @navigation-block.end != 0;

my @pages;
@pages.push: "$domain/issues/";
@navigation-block[0][0].getElementsByTagName('a').map: { @pages.push: "$domain$(.attribs{'href'})"};

for @pages.values {
    my $page-content = LibCurl::Easy.new(URL => $_).perform.content(enc => 'utf-8');
    die "Not page content at $_" if not $page-content;

    my $issues-list = parse-html($page-content, :TAG<div>, :class<issues-list>);
    die "No issues list at $_" if not $issues-list;

    my @li-elems = $issues-list.elements[0][1].elements(:TAG<li>);
    for @li-elems {
        my %record;
        if .getElementsByTagName('img').elems > 0 {
            %record{'title'} = .getElementsByTagName('img')[0].attribs{'alt'};
            %record{'imgURL'} = $domain ~ .getElementsByTagName('img')[0].attribs{'src'};
        } else {
            %record{'title'} = '';
            %record{'imgURL'} = '';
        }
        if .getElementsByTagName('a').elems > 0 {
            %record{'pdfURL'} = $domain ~ .getElementsByTagName('a')[0].attribs{'href'};
        } else {
            %record{'pdfURL'} = '';
        }
        @records.push: %record;
    }
}

my $fh = open "../assets/journal.json", :rw;
my $fh-news = open "../assets/news.txt", :w;

my @prev-records = from-json($fh.IO.slurp);

if @prev-records[0].elems < @records.elems {
    $fh-news.print: "- Новых выпусков: $(@records.elems - @prev-records[0].elems)\n";
}

$fh-news.close;

$fh.print: to-json(@records);
$fh.close;
