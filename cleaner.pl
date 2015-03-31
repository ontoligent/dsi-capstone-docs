use strict;
use HTML::Strip;
use utf8;

# Instantiate an object for stripping HTML below
my $hs = HTML::Strip->new();

# Create an start the XML file for dumping the cleaned data
open XML, ">10k.xml";
binmode(XML, ":utf8");
print XML "<docs>\n";

# Loop through the source file directory and do your business
my @files = `ls sample-data/*.txt`;
for my $file (@files) {

	# Remove new line if there is one
	chomp $file;

	# Open the source file, which is full of HTML
	open IN, $file;
	my @raw_html = <IN>;
	my $raw_html = join "\n", @raw_html;
	close IN;
	
	# Remove the HTML with the object created above
	my $clean_text = $hs->parse($raw_html);
	
	# Reduce multiple new lines to one
	$clean_text =~ s/\n+/\n/gm;
	
	# Loop through the new text line by line and create an XML element for each
	my @clean_text = split "\n", $clean_text;
	my $s1 = 0; # print line on/off switch
	my $s2 = 0; # print doc on/off switch
	my $content = '';
	my $company = '';
	my $sector = '';
	for my $line (@clean_text) {
		if ($line =~ /^\s*COMPANY CONFORMED NAME:\s+(.+)\s*$/i) {
			$company = $1;
			next;
		}
		if ($line =~ /^\s*STANDARD INDUSTRIAL CLASSIFICATION:\s+(.+)\s*$/i) {
			$sector = $1;
			next;
		}
		if ($line =~ /^\s*Item 7[. ]/i) {
			$s1 = 1;
			$s2 = 1;
			next;
		}
		if ($line =~ /^\s*Item 8[. ]/i) {
			$s1 = 0;
			last;	
		}
		if ($line =~ /Not Applicable/) {
			next;
		}
		if ($line =~ /Quantitative and Qualitative Disclosures About Market/i) {
			next;
		}
		if ($line =~ /Item 7A/i) {
			next;
		}
		if ($line =~ /ANALYSIS OF FINANCIAL CONDITION/i) {
			next;
		}
		if ($line =~ /^\s*$/) {
			next;
		}
		$content .= "$line " if $s1;
	}
	$content =~ s/\d+/ /g;
	$content =~ s/\W+/ /g;
	$content =~ s/\s+/ /g;
	if ($content !~ /^\s*$/ && $s2) {
		my $id = $file;
		$id =~ s/sample-data\/(.+)\.txt/$1/;
		print XML "\t<doc>\n";
		print XML "\t\t<id>$id</id>\n";
		print XML "\t\t<company>$company</company>\n";
		print XML "\t\t<sector>$sector</sector>\n";
		print XML "\t\t<c><![CDATA[$content]]></c>\n";
		print XML "\t</doc>\n";	
	}
	
	# Clean out the object for reuse
	$hs->eof;
	
	# Print the cleaned content to an external file for sake keeping
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