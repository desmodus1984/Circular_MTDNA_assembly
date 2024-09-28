for i in *.fastq
        do
	base=$(basename $i ".fastq")

echo -e '\nInitial fastq stats\n'
seqkit stat ${base}.fastq

echo '\nFiltering low quality reads'

#filter low quality reads
seqkit seq -m 250 -Q 15 -g ${base}.fastq > ${base}.m250Q15.fastq

echo -e '\nAfter filtering fastq stats\n'
seqkit stat ${base}.m250Q15.fastq

echo '\nMapping reads to C elegans mitogenome\n'

# Map filtered reads to c elegans mitogenome - retrieve only primary and supplementary reads
mini_align -r /DataDrive/juaguila/Fr-worms/c.ele.mito.fasta -i ${base}.m250Q15.fastq -y -t 12 -p ${base}.m250Q15

echo '\nMapping stats\n'
samtools flagstat ${base}.m250Q15.bam

echo '\nExtracting mapped reads\n'

#Get good-quality mapped reads from bam file
samtools view -b -h -q 20 -F 4 ${base}.m250Q15.bam > ${base}.mapped.bam

echo '\nMapping stats\n'
samtools flagstat ${base}.mapped.bam

echo '\nExtracting mapped reads in fastq format\n'

#Get reads in fastq format from bam file
samtools fastq ${base}.mapped.bam > ${base}.mapped.fastq

echo -e '\nfastq stats\n'
seqkit stat ${base}.mapped.fastq

echo '\nCreating gfa file\nSelf aligning reads\n'

#Create gfa file

#1 Self-align
minimap2 -x ava-ont ${base}.mapped.fastq ${base}.mapped.fastq | gzip -1 > ./${base}.mapped.paf.gz

echo '\nGetting the gfa file\n'

#2 Create the gfa file from self-mapping
miniasm -f ${base}.mapped.fastq ./${base}.mapped.paf.gz > ${base}.mapped.gfa

echo -e '\nPolishing gfa\nto get a circular reads\n'

#3 Polish - hope to get circular mitogenome
minipolish -t 12 ${base}.mapped.fastq ${base}.mapped.gfa > ${base}.mapped.polish.gfa 

done
