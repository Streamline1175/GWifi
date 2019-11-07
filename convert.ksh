#!/bin/ksh

FILE1=$1
FILE2="htmlfile.html"
echo -e '<html>\n<table border="1">' > $FILE2
cat $FILE1 | sed 's/^/<tr><td>/;s/$/<\/td><\/tr>/;s/~/<\/td><td>/g' >> $FILE2
echo -e '</table></html>' >> $FILE2