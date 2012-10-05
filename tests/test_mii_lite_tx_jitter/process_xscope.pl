<>;
<>;
<>;
<>;
<>;
<>;
<>;
<>;
<>;

my $ini = <>;
( my $x ) = $ini =~ /.*User="(\d+)"/;

while (<>) {

( my $y ) = /.*User="(\d+)"/;

my $d = int($y) - int($x);
$x = $y;

print $d,"\n";


}

