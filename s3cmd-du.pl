#!/usr/bin/perl

$bucket = $ARGV[0];

$total_bits_cmd = "s3cmd du $bucket | awk '{print \$1}' | awk '{total+=\$0}END{print total}'";
$total_bits = `$total_bits_cmd`;
chomp($total_bits);

if ($total_bits != "0") {
	$total_h_cmd = "awk 'BEGIN{x=\"$total_bits\"; split(\"B KB MB GB TB PB\",type); for(i=5;y<1;i--) y=x/(2**(10*i)); print y type[i+2]}'";
	$total_h = `$total_h_cmd`;
	chomp($total_h);
}
else {
	$total_h = "0B";
}

print STDOUT "$bucket	$total_h\n";
