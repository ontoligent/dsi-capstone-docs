use strict;
use HTML::Strip;
use utf8;

my @headers = qw/
Net Income
Cost of Inflation
Net Revenunes
Operations?
Quantitative and Qualitative Disclosure About Market Risk
Results of Operations
General Overview
General
Overview
Executive Overview
Revenues
Cost of Renenues
Research and Development
Selling, General, and Administrative
Income from Operations
/;
my $headers = join "|", @headers;
my $header_pat = qr/^\s*($headers)\s*$/i;

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

	# Open the source file, which is full of crappy HTML
	open IN, $file;
	my @raw_html = <IN>;
	my $raw_html = '';
	my $s = 0;
	for my $line (@raw_html) {
		$s = 1 if ($line =~ /\/SEC-HEADER/);
		if ($s) {
			chomp $line; # Remove line breaks
			$line =~ s/(<\/[^>]+>)/$1\n/gm; # Add them to the end of elements
		}
		$raw_html .= $line . " "; # Append to the new doc
	}
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
	
		# Grab info
		if ($line =~ /^\s*COMPANY CONFORMED NAME:\s+(.+)\s*$/i) {
			$company = $1;
			next;
		}
		if ($line =~ /^\s*STANDARD INDUSTRIAL CLASSIFICATION:\s+(.+)\s*$/i) {
			$sector = $1;
			next;
		}
		
		# Turn switches on and off
		if ($line =~ /^\s*Item 7[. ]/i) {
			$s1 = 1;
			$s2 = 1;
			next;
		}
		if ($line =~ /^\s*Item 8[. ]/i) {
			$s1 = 0;
			last;	
		}
		
		# Skip extraneous content
		next if (
			   $line =~ /Not Applicable/i
			|| $line =~ /Quantitative and Qualitative Disclosures? About Market/i
			|| $line =~ /^\s*Item 7A/i
			|| $line =~ /DISCUSSION AND ANALYSIS OF FINANCIAL CONDITION/i
			|| $line =~ /^\s*$/
			|| $line =~ $header_pat
		);
		
		# Gather content if on
		$content .= "$line " if $s1;
	}
	
	# Straighten out content
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