## assuming you have: 1) VCF/SNP files for two strains and 2) NGS reads for hybrids of these two strains.
## with these two files, this script will:
#### 1) create an N-masked genome over all SNPs
#### 2) align reads to N-masked genome and remove duplicates
#### 3) use SNPsplit to sort allele-specific reads
# (find SNPsplit documentation at https://github.com/FelixKrueger/SNPsplit/blob/master/SNPsplit_User_Guide.md)

# assign file paths:
$vcf_file= #gatk HaplotypeCaller --genotyping-mode DISCOVERY --output-mode EMIT_ALL_SITES
$reference_genome=
$masked_ref_genome=
$index_name=
$indexed_genome=
$forward_reads=
$reverse_reads=
$SAMPLE_NAME=
$SNP_file_SNPsplit_format=
$sample_list=

#### 1) create an N-masked genome over all SNPs #####
# run bedtools program
bedtools maskFastaFromBed \
   -fi $reference_genome \
   -fo $masked_ref_genome \
   -bed $vcf_file

## before proceeding, check that it worked using something like bedtools getFastaFromBed at SNP intervals

#### 2) align reads to N-masked genome and remove duplicates ######
# index N-masked genome
bowtie2-build $masked_ref_genome $index_name

# align reads to masked and indexed genome
bowtie2 -p 8 -x $indexed_genome \
        -1 $forward_reads \
        -2 $reverse_reads \
        -S ${SAMPLE_NAME}_masked_ZHRZ30.sam
samtools sort -O BAM -o ${SAMPLE_NAME}_masked_ZHRZ30.bam \
        ${SAMPLE_NAME}_masked_ZHRZ30.sam
samtools index ${SAMPLE_NAME}_masked_ZHRZ30.bam

# mark duplicates, remove, and sort/index
java -jar /nfs/turbo/lsa-wittkopp/Lab/Henry/executables/picard-2.jar MarkDuplicates \
      I=${SAMPLE_NAME}_masked_ZHRZ30.bam \
      O=${SAMPLE_NAME}_masked_ZHRZ30_md.bam \
      M=${SAMPLE_NAME}_masked_ZHRZ30_md_report.txt \
      REMOVE_DUPLICATES=true
samtools sort -O BAM -o ${SAMPLE_NAME}_masked_ZHRZ30_NoDup.bam \
        ${SAMPLE_NAME}_masked_ZHRZ30_NoDup.bam
samtools index ${SAMPLE_NAME}_masked_ZHRZ30_NoDup.bam

#### 3) use SNPsplit to sort allele-specific reads
# get VCF file in this format:
## SNP-ID     Chromosome  Position    Strand   Ref/SNP
# run all samples in one line
SNPsplit --snp_file $SNP_file_SNPsplit_format $sample_list #${SAMPLE_NAME}_masked_ZHRZ30_NoDup.bam
