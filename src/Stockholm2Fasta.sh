for f in $1
do
    perl Stockholm2Fasta.pl $f > ${f%.stockholm}.fasta
done
