use v6;
use LibCurl::Easy;
use Gumbo;
use JSON::Fast;

my $domain = 'https://vegjournal.com';
my @records;

my $fh = open "../assets/journal.json", :w;

for 1..5 {
    my $page = LibCurl::Easy.new(URL => "$domain/issues/?PAGEN_1=$_").perform.content(enc => 'utf-8');
    my $refs = parse-html($page, :TAG<div>, :class<issues-list>).elements[0][1].elements(:TAG<li>);
    for 0..$refs.elems-1 -> $i {
        my %record;
        if $refs[$i].getElementsByTagName('img').elems > 0 {
            %record{'title'} = $refs[$i].getElementsByTagName('img')[0].attribs{'alt'};
            %record{'imgURL'} = $domain ~ $refs[$i].getElementsByTagName('img')[0].attribs{'src'};
        } else {
            %record{'title'} = '';
            %record{'imgURL'} = '';
        }
        if $refs[$i].getElementsByTagName('a').elems > 0 {
            %record{'pdfURL'} = $domain ~ $refs[$i].getElementsByTagName('a')[0].attribs{'href'};
        } else {
            %record{'pdfURL'} = '';
        }
        @records.push: %record;
    }
}

$fh.print: to-json(@records);
$fh.close;
