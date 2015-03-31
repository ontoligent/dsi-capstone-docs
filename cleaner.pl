use strict;
use HTML::Strip;
use utf8;

my $hs = HTML::Strip->new();

my @files = `ls sample-data/*.txt`;
open XML, ">10k.xml";
binmode(XML, ":utf8");

print XML "<docs>\n";

for my $file (@files) {

	chomp $file;

	open IN, $file;
	my @raw_html = <IN>;
	my $raw_html = join "\n", @raw_html;
	close IN;
	
	my $clean_text = $hs->parse($raw_html);
	$clean_text =~ s/\n+/\n/gm;
	my @clean_text = split "\n", $clean_text;
	my $s = 0; # print on/off switch
	print XML "\t<doc>\n";
	print XML "\t\t<id>$file</id>\t";
	print XML "\t\t<c>";
	for my $line (@clean_text) {
		$s = 1 if $line =~ /^\s*Item 7[. ]/i;
		$s = 0 if $line =~ /^\s*Item 8[. ]/i;
		print XML "$line " if $s;
	}
	print XML "\t\t</c>\n";
	print XML "\n\t</doc>\n";
	$hs->eof;
	
	my $outfile = $file;
	$outfile =~ s/sample-data/out/;
	open OUT, ">$outfile";
	binmode(OUT, ":utf8");
	print OUT $clean_text;
	close OUT;
	
}

print XML "</docs>\n";
close XML;

exit;