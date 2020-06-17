#!/bin/bash
tissue=$1

USAGE="\nMissing input arguments..\n
This script is adjusted to precancer data structure\n
You can run it anywhere\n
USAGE:\post_evc.sh \\
        precancer type\n\n"

if [ -z "$1" ]
then
        printf "$USAGE"
        exit 1
fi

genome=$(echo /projects/ps-lalexandrov/shared/Reference_Genomes/chrom_sizes/hg38.chrom.sizes)

cd /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue} 
echo starting post_evc for tissue $tissue ...
mkdir all_mutations/
echo Copying files over...
# Copy over snp files
cp PCGA*/varscan/*snp.Somatic.hc.vcf all_mutations/
cp PCGA*/mutect/*mutect2_filtered.vcf all_mutations/
for f in PCGA*/; do fa=`basename $f /`;cp $f/strelka/results/variants/somatic.snvs.vcf all_mutations/${fa}_strelka_snv.vcf;done
for f in PCGA*/muse/*vcf;do fa=`basename -- $f`;fb=`basename $f .vcf`;cp $f all_mutations/${fb}_muse_snv.vcf;done
# Copy over indel files
cp PCGA*/varscan/*.indel.Somatic.hc.vcf all_mutations/
cp PCGA*/mutect/*mutect2_filtered.vcf all_mutations/
for f in PCGA*/; do fa=`basename $f /`;cp $f/strelka/results/variants/somatic.indels.vcf all_mutations/${fa}_strelka_indel.vcf;done

#Fix file names
echo Renaming files...
cd all_mutations/
for f in *snp.Somatic.hc.vcf;do fa=`basename $f .snp.Somatic.hc.vcf`;mv $f ${fa}_varscan_snv.vcf;done
for f in *mutect2_filtered.vcf;do fa=`basename $f _mutect2_filtered.vcf`;mv $f ${fa}_mutect.vcf;done
for f in *indel.Somatic.hc.vcf;do fa=`basename $f .indel.Somatic.hc.vcf`;mv $f ${fa}_varscan_indel.vcf;done
mkdir snvs_filtered
mkdir indels_filtered
mkdir special_mutations

# Fix muse files
echo Fixing MuSE files...
for f in *_muse_snv.vcf;
do fa=`basename $f _muse_snv.vcf`;
cat $f|awk 'length($5)>1'> special_mutations/${fa}_muse_snvMulti.txt;
cat $f|awk '{OFS="\t";print $1,$2,".",$4,substr($5,1,1),$6,$7,$8,$9,$11,$10}'>a;
mv a $f;
done

# Fix mutect files
echo Fixing MuTect files...
for f in *_mutect.vcf;
do
normal_name=$(grep normal_sample $f | cut -d= -f2)
tumor_name=$(grep tumor_sample $f | cut -d= -f2)
swapped_file=$(basename $f .vcf).swapped.vcf
multiallelic_file=$(basename $f .vcf).multiMutation.txt
biallelic_file=$(basename $f .vcf).biallelic.vcf
indel_file=$(basename $f .vcf)_indel.vcf
snv_file=$(basename $f .vcf)_snv.vcf
separated_snvs_file=$(basename $f .vcf).snv.separated.vcf

#change this if additional steps are added
final_vcf=${separated_snvs_file}
final_file=$(basename $f .vcf)_snv.vcf

##################
## Swap columns ##
##################

#col10 is the first column
if [ "$(grep "CHROM" $f | cut -f10)" == "${tumor_name}" ]
then
	#echo Wrong order. Swapping columns...
	awk 'BEGIN{OFS="\t";}; { t = $10; $10 = $11; $11 = t; print; }' $f > ${swapped_file}
else
	#echo Correct order. Copying to sample_swapped.vcf...
	#make a copy to match naming
	cp $f ${swapped_file}
fi

###########################
## Multiallele processing ##
###########################

#echo Isolating biallelic variants...
#if col5 has commas, it is multiallelic
grep -v "#" ${swapped_file} | awk 'BEGIN{OFS="\t";}; $5 ~ /,/ { print }' > special_mutations/${multiallelic_file}
grep -v "#" ${swapped_file} | awk 'BEGIN{OFS="\t";}; ! ($5 ~ /,/) { print }' > ${biallelic_file}


#echo Separating SNVs and Indels...
#indels
awk 'BEGIN{OFS="\t";}; length($4) != length($5) { print }' ${biallelic_file} > ${indel_file}
#snvs
awk 'BEGIN{OFS="\t";}; length($4) == length($5) { print }' ${biallelic_file} > ${snv_file}

#echo Separating multinecleotide SNVs...
#if len($4) > 1 then this is a group
awk 'BEGIN{OFS="\t";};
	{if (length($4) > 1) {
		totalLen = length($4);
		ref=$4;
		alt=$5;
		for (i = 1; i <= totalLen; i++) {
			new_ref=substr(ref, i, 1);
			new_alt=substr(alt, i, 1);
			$4 = new_ref
			$5 = new_alt
			$2 = $2 + i - 1
			print
		}
	}
	else {print}
}' ${snv_file} > ${separated_snvs_file}

#########################
## Generate final file ##
#########################

grep "#" ${swapped_file} > ${final_file}
cat ${final_vcf} >> ${final_file}
rm $f
done

rm *.swapped.vcf *.biallelic.vcf *.snv.separated.vcf

# Collecting filtered files
for f in *indel.vcf; do cat $f|grep PASS|grep -v "#">indels_filtered/$f;done
for f in *snv.vcf; do cat $f|grep PASS|grep -v "#">snvs_filtered/$f;done

echo Merging INDELs..
cd indels_filtered
mkdir 2outof3 3outof3
for f in *_varscan_indel.vcf;do fa=`basename $f _varscan_indel.vcf`;cat ${fa}*|cut -f1-5|sort|uniq -c|awk '$1>1'|awk '{OFS="\t";print $2,$3,$4,$5,$6}'| grep -v "_" | grep -v chrM>2outof3/${fa}_2outof3.vcf;done
for f in *_varscan_indel.vcf;do fa=`basename $f _varscan_indel.vcf`;cat ${fa}*|cut -f1-5|sort|uniq -c|awk '$1>2'|awk '{OFS="\t";print $2,$3,$4,$5,$6}'| grep -v "_" | grep -v chrM>3outof3/${fa}_3outof3.vcf;done
mkdir mutect_indels varscan_indels strelka_indels
mv *mutect_indel.vcf mutect_indels
mv *strelka_indel.vcf strelka_indels
mv *varscan_indel.vcf varscan_indels 


echo Merging SNVs...
cd ../snvs_filtered
mkdir 2outof4 3outof4 4outof4
#merging
for f in *_varscan_snv.vcf;do fa=`basename $f _varscan_snv.vcf`;cat ${fa}*|cut -f1-5|sort|uniq -c|awk '$1>1'|awk '{OFS="\t";print $2,$3,$4,$5,$6}'| awk '{$6=".";$7="PASS";$8=".";$9=".";print}' OFS='\t'| grep -v "_" | grep -v chrM>2outof4/${fa}_2outof4.vcf;done
for f in *_varscan_snv.vcf;do fa=`basename $f _varscan_snv.vcf`;cat ${fa}*|cut -f1-5|sort|uniq -c|awk '$1>2'|awk '{OFS="\t";print $2,$3,$4,$5,$6}' | awk '{$6=".";$7="PASS";$8=".";$9=".";print}' OFS='\t'| grep -v "_" | grep -v chrM>3outof4/${fa}_3outof4.vcf;done
for f in *_varscan_snv.vcf;do fa=`basename $f _varscan_snv.vcf`;cat ${fa}*|cut -f1-5|sort|uniq -c|awk '$1>3'|awk '{OFS="\t";print $2,$3,$4,$5,$6}'| awk '{$6=".";$7="PASS";$8=".";$9=".";print}' OFS='\t'| grep -v "_" | grep -v chrM>4outof4/${fa}_4outof4.vcf;done
mkdir mutect_snvs muse_snvs strelka_snvs varscan_snvs
mv *muse_snv.vcf muse_snvs
mv *mutect_snv.vcf mutect_snvs
mv *strelka_snv.vcf strelka_snvs
mv *varscan_snv.vcf varscan_snvs

####################################
## annotating in 2out4 snv folder ##
####################################
echo starting annotation in 2outof4 snv folder

cd /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}/all_mutations/snvs_filtered/2outof4
mkdir tmp

##### running bseq #####
echo running bseq

source ~/.bashrc
conda activate py2
for f in *_2outof4.vcf;do
fa=`basename $f _2outof4.vcf`
cat ~/bseq/header $f > ${f}.tmp
dkfzbiasfilter.py \
${f}.tmp \
/restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}/${fa}/${fa}_tumor_mkdp.bam \
/restricted/alexandrov-group/shared/Reference_Genomes/GRCh38.d1.vd1/GRCh38.d1.vd1.fa \
${fa}_2outof4_bseq.vcf \
--tempFolder=/restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}/all_mutations/snvs_filtered/2outof4/tmp \
--mapq=1 \
--baseq=1;
grep -v "#" ${fa}_2outof4_bseq.vcf >a; mv a ${fa}_2outof4_bseq.vcf
rm ${f}.tmp
done
conda deactivate

echo $tissue is finished with bseq annotation... $(date)


##### running igv annotation #####
ln -s /projects/ps-lalexandrov/shared/vep_ref ~/.vep
ls -d PCGA*_2outof4_bseq.vcf | cut -d '_' -f1 | while read line;
do
	echo now igv processing sample $line ... $(date)
	merged=$(echo ${line}_2outof4_bseq.vcf);
	annotated=$(echo ${line}_2outof4_bseq_igv.vcf);
	tbam=$(echo /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/$tissue/$line/${line}_tumor_final.bam)
	nbam=$(echo /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/$tissue/$line/${line}_normal_final.bam)

	#for each variant converted to bed format (chr:start-end)
	cat $merged|awk '{OFS="";print $1,":",$2,"-",$2}'|while read query;
	do
		#get numbers for each variant using igvtools and print to a .wig
		~/ConsensusSomaticMutationsPipeline/IGV_2.6.2/igvtools count --bases --strands read -w 1 --minMapQuality 30 --query $query $nbam normal.wig $genome>/dev/null 2>&1;
		~/ConsensusSomaticMutationsPipeline/IGV_2.6.2/igvtools count --bases --strands read -w 1 --minMapQuality 30 --query $query $tbam tumor.wig $genome>/dev/null 2>&1;
		
		#if the wig is empty, then print message to stdout and 0's to file
		if [ $(wc -l normal.wig |awk -F" " '{print $1}') == 0 ]
		then
			echo "NOTE: Sample $(echo $line|cut -d ' ' -f1) doesn't have any good quality reads in normal at $query"
			echo "0:0:0:0:0:0:0:0">>normal.txt
		else
			#else cat the wig into the combined normal.txt file 
			cat normal.wig |tail -1|awk -F'[."\t"]' '{print $2,$4,$6,$8,$16,$18,$20,$22}'|tr ' ' ':'>>normal.txt;
		fi

		#repeat for tumor
		if [ $(wc -l tumor.wig |awk -F" " '{print $1}') == 0 ]
		then 
			echo "NOTE: Sample $(echo $line|cut -d ' ' -f1) doesn't have any good quality reads in tumor at $query"
			echo "0:0:0:0:0:0:0:0">>tumor.txt
		else 
			cat tumor.wig |tail -1|awk -F'[."\t"]' '{print $2,$4,$6,$8,$16,$18,$20,$22}'|tr ' ' ':'>>tumor.txt;
		fi
	done

	#for each sample, add the normal and tumor annotations as columns and print to annotated
	paste -d "\t" $merged normal.txt tumor.txt>$annotated
	rm normal.txt tumor.txt *.wig
	awk '{$9="PA:PC:PG:PT:NA:NC:NG:NT:RD:AD:VAF";print}' OFS='\t' $annotated > a; mv a $annotated
	echo $merged is finished with igv annotation... $(date)
done

rm -r tmp
echo $tissue is finished with post_evc... $(date)



##### getting information from VC and calculating RD,AD,VAF #####
for f in *_2outof4_bseq_igv.vcf;do
fa=`basename $f _2outof4_bseq_igv.vcf`;
awk -F "\t" 'NR==FNR{a[$1$2$3$4$5]=$8;next} NR>FNR{if($1$2$3$4$5 in a){OFS="\t";if($6=="."){$6="mt"}else{$6=$6",mt"};print $0"\t"a[$1$2$3$4$5]}else{OFS="\t";print $0"\t."}}' ../mutect_snvs/${fa}_mutect_snv.vcf $f>${fa}_match1.vcf

awk -F "\t" 'NR==FNR{a[$1$2$3$4$5]=$8;next} NR>FNR{if($1$2$3$4$5 in a){OFS="\t";if($6=="."){$6="vs"}else{$6=$6",vs"};print $0"\t"a[$1$2$3$4$5]}else{OFS="\t";print $0"\t."}}' ../varscan_snvs/${fa}_varscan_snv.vcf ${fa}_match1.vcf>${fa}_match2.vcf

awk -F "\t" 'NR==FNR{a[$1$2$3$4$5]=$8;next} NR>FNR{if($1$2$3$4$5 in a){OFS="\t";if($6=="."){$6="st"}else{$6=$6",st"};print $0"\t"a[$1$2$3$4$5]}else{OFS="\t";print $0"\t."}}' ../strelka_snvs/${fa}_strelka_snv.vcf ${fa}_match2.vcf>${fa}_match3.vcf

awk -F "\t" 'NR==FNR{a[$1$2$3$4$5]=$8;next} NR>FNR{if($1$2$3$4$5 in a){OFS="\t";if($6=="."){$6="ms"}else{$6=$6",ms"};print $0"\t"a[$1$2$3$4$5]}else{OFS="\t";print $0"\t."}}' ../muse_snvs/${fa}_muse_snv.vcf ${fa}_match3.vcf>${fa}_match4.vcf

cat ${fa}_match4.vcf|awk '{OFS="\t";a=substr($8,3);$8=a"|"$12"|"$13"|"$14;print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}'|
awk -F"\t" '{
		OFS=FS;
		split($10,n,":");
		split($11,t,":");
		ndep=n[1]+n[2]+n[3]+n[4]+n[5]+n[6]+n[7]+n[8]
		tdep=t[1]+t[2]+t[3]+t[4]+t[5]+t[6]+t[7]+t[8]
		if($4=="A"){
			Rfn=n[1]
			Rrn=n[5]
			nrd=n[1]+n[5]
			trd=t[1]+t[5]	
		}
		else if($4=="C"){
			Rfn=n[2]
			Rrn=n[6]
			nrd=n[2]+n[6]
			trd=t[2]+t[6]		
		}
		else if($4=="G"){
			Rfn=n[3]
			Rrn=n[7]
			nrd=n[3]+n[7]
			trd=t[3]+t[7]
		}
		else if($4=="T"){
			Rfn=n[4]
			Rrn=n[8]
			nrd=n[4]+n[8]
			trd=t[4]+t[8]
		}
		if($5=="A"){
			Aft=t[1]
			Art=t[5]
			vaf=(tdep==0?0:(t[1]+t[5])/tdep)
			nvaf=(ndep==0?0:(n[1]+n[5])/ndep)
			nad=n[1]+n[5]
			tad=t[1]+t[5]
		}
		else if($5=="C"){
			Aft=t[2]
			Art=t[6]
			vaf=(tdep==0?0:(t[2]+t[6])/tdep)
			nvaf=(ndep==0?0:(n[2]+n[6])/ndep)
			nad=n[2]+n[6]
			tad=t[2]+t[6]
		}
		else if($5=="G"){
			Aft=t[3]
			Art=t[7]
			vaf=(tdep==0?0:(t[3]+t[7])/tdep)
			nvaf=(ndep==0?0:(n[3]+n[7])/ndep)
			nad=n[3]+n[7]
			tad=t[3]+t[7]
		}
		else if($5=="T"){
			Aft=t[4]
			Art=t[8]
			vaf=(tdep==0?0:(t[4]+t[8])/tdep)
			nvaf=(ndep==0?0:(n[4]+n[8])/ndep)
			nad=n[4]+n[8]
			tad=t[4]+t[8]
		}
		$10=$10":"nrd":"nad":"nvaf
		$11=$11":"trd":"tad":"vaf
		print}' >${fa}_bseq_igv_annotated.vcf
done
rm *match*vcf


#####################################
## generating final_results folder ##
#####################################

cd /restricted/alexandrov-group/shared/precancer_analysis/new_analysis/${tissue}
mkdir final_results
cp all_mutations/snvs_filtered/2outof4/*_bseq_igv_annotated.vcf final_results
chmod -R 775 final_results all_mutations
