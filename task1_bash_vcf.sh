#!/bin/bash

basedirectory="/home/roshny/AbiomixTestFiles/basedirectory"
input_vcf="testsample.vcf.gz"
report_file="task1_statistical_report.txt"

exec > "$basedirectory/$report_file" 2>&1

# Create directory structure
for chr in chr{1..22} chrX chrY; do
    mkdir -p "$basedirectory/chromosome_$chr"
done

# Split VCF into chromosome specific files
for chr in chr{1..22} chrX chrY; do
    chrom_directory="$basedirectory/chromosome_$chr"
    
    # Split VCF based on chromosome
    bcftools view -r ${chr} -O z -o "$chrom_directory/testsample.chromosome${chr}.vcf.gz" "$input_vcf"
    bcftools index "$chrom_directory/testsample.chromosome${chr}.vcf.gz"
done

# Filteration of VCF files
for chr in chr{1..22} chrX chrY; do
    chrom_directory="$basedirectory/chromosome_$chr"
    
    # Filter VCF based on criteria
    bcftools view -i 'INFO/DP>10 & QUAL>10' -r ${chr} -O z -o "$chrom_directory/testsample.chromosome${chr}.pass.vcf.gz" "$input_vcf"
    bcftools index "$chrom_directory/testsample.chromosome${chr}.pass.vcf.gz"
    
done

# Calculation of statistics
for chr in chr{1..22} chrX chrY; do
    chrom_directory="$basedirectory/chromosome_$chr"
    
    echo "Tabulating statistics for Chromosome $chr"
    
    # Non-filtered VCF statistics
    bcftools stats "$chrom_directory/testsample.chromosome${chr}.vcf.gz" > "$chrom_directory/stats_non_filtered.txt"
    
    # Filtered VCF statistics
    bcftools stats "$chrom_directory/testsample.chromosome${chr}.pass.vcf.gz" > "$chrom_directory/stats_filtered.txt"

    # Display basic statistics
    echo -e "\nChromosome $chr Statistics:"
    grep -E "number of records:|number of SNPs:|number of indels:|number of homozygous genotypes:|number of heterozygous genotypes:" "$chrom_directory/stats_non_filtered.txt" "$chrom_directory/stats_filtered.txt"

    # Summary statistics of INFO/DP
    echo -e "\nSummary Statistics of INFO/DP Field:"
    bcftools query -f '%INFO/DP\n' "$chrom_directory/testsample.chromosome${chr}.vcf.gz" | awk '{sum+=$1; count+=1} END {print "Mean:", sum/count, "Median:", (count%2 ? a[count/2] : (a[count/2-1]+a[count/2])/2)}'

    # Summary statistics of INFO/AF
    echo -e "\nSummary Statistics of INFO/AF Field:"
    bcftools query -f '%INFO/AF\n' "$chrom_directory/testsample.chromosome${chr}.vcf.gz" | awk '{sum+=$1; count+=1} END {print "Mean:", sum/count, "Median:", (count%2 ? a[count/2] : (a[count/2-1]+a[count/2])/2)}'
    
    echo "Tabulation completed for Chromosome $chr"
done

for chr in chr{1..22} chrX chrY; do
    chrom_directory="$basedirectory/chromosome_$chr"
    
    # Non-filtered VCF statistics
    bcftools stats "$chrom_directory/testsample.chromosome${chr}.vcf.gz" > "$chrom_directory/stats_non_filtered.txt"
    
    # Filtered VCF statistics
    bcftools stats "$chrom_directory/testsample.chromosome${chr}.pass.vcf.gz" > "$chrom_directory/stats_filtered.txt"

    # Display basic statistics
    echo -e "\nChromosome $chr Statistics:"
    grep -E "number of records:|number of SNPs:|number of indels:|number of homozygous genotypes:|number of heterozygous genotypes:" "$chrom_directory/stats_non_filtered.txt" "$chrom_directory/stats_filtered.txt"

    # Summary statistics of INFO/DP
    echo -e "\nSummary Statistics of INFO/DP Field:"
    bcftools query -f '%INFO/DP\n' "$chrom_directory/testsample.chromosome${chr}.vcf.gz" | awk '{sum+=$1; count+=1} END {print "Mean:", sum/count, "Median:", (count%2 ? $a[count/2] : ($a[count/2-1]+$a[count/2])/2)}'

    # Summary statistics of INFO/AF
    echo -e "\nSummary Statistics of INFO/AF Field:"
    bcftools query -f '%INFO/AF\n' "$chrom_directory/testsample.chromosome${chr}.vcf.gz" | awk '{sum+=$1; count+=1} END {print "Mean:", sum/count, "Median:", (count%2 ? $a[count/2] : ($a[count/2-1]+$a[count/2])/2)}'
    
done

# Function to calculate mean and median
calculate_stats() {
    local column_values=("$@")
    local sum=0
    local count=${#column_values[@]}
    
    # Calculate sum
    for value in "${column_values[@]}"; do
        ((sum += value))
    done
    
    # Calculate mean
    local mean=$((sum / count))
    
    # Calculate median
    local median
    local sorted_values=($(for i in "${column_values[@]}"; do echo $i; done | sort -n))
    if ((count % 2 == 0)); then
        local mid1=$((count / 2 - 1))
        local mid2=$((count / 2))
        median=$(( (sorted_values[mid1] + sorted_values[mid2]) / 2 ))
    else
        local mid=$((count / 2))
        median="${sorted_values[mid]}"
    fi
    
    echo "Mean: $mean"
    echo "Median: $median"
}

