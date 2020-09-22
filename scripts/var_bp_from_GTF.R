# var_bp_from_GTF.R
# Rscript --vanilla var_bp_from_GTF.R <gtf_file_path>

library('GenomicTools')
library('dplyr')

# get gtf filename
argc = length(commandArgs())
gtf_filename = commandArgs(trailingOnly = F)[argc]

var_bp = c()
# grab gtf entries
genes = importGTF(gtf_filename,level = "gene",features=c("gene_id","gene_name"))
transcripts=importGTF(gtf_filename,level = "transcript", features=c("gene_id","gene_name","transcript_id"))
exons=importGTF(gtf_filename,level = "exon", features=c("transcript_id","exon_number"))
results = genes[,c("gene_id","gene_name")]
results$n_gene_var_bp = 0
# loop that goes through genes and counts up base pairs that would be in your "splice variant window" (i.e -i2 e3)
for(gene_i in 1:nrow(genes)){
  gene = genes[gene_i,]
  gene_var_bp = c() # splice variant window base position strings
  gene_transcripts = transcripts[transcripts$gene_id == gene$gene_id,]
  # for each gene_transcript
  for(gene_transcript_i in 1:nrow(gene_transcripts)){
     transcript_id = gene_transcripts[gene_transcript_i,]$transcript_id
     from_transcript = exons$transcript_id == transcript_id # censor
     gene_transcript_exons = exons[from_transcript,]
     # for each exon in each gene_transcript
     for(gene_transcript_exon_i in 1:nrow(gene_transcript_exons)){
       exon = gene_transcript_exons[gene_transcript_exon_i,]
       chr = exon$V1
       if (exon$exon_number != 1){ # not start of transcript 
         exon_start = exon$V4
         exon_start_bp = -2:3 + exon_start
         chr_exon_start_bp = sub("^",paste(chr,":"),exon_start_bp) # not strictly necessary to have colon, just makes it clearer what we're doing
         gene_var_bp = c(gene_var_bp, chr_exon_start_bp)
       }
       if (exon$exon_number != length(gene_transcript_exons)){ # not end of transcript
         exon_end = exon$V5
         exon_end_bp = -3:2 + exon_end
         chr_exon_end_bp = sub("^",paste(chr,":"),exon_end_bp) # not strictly necessary to have colon, just makes it clearer what we're doing
         gene_var_bp = c(gene_var_bp, chr_exon_end_bp)
       }
     }
     gene_var_bp = unique(gene_var_bp)
     results[results$gene_name == gene$gene_name,]$n_gene_var_bp = length(gene_var_bp)
   }
  var_bp = unique(c(var_bp,gene_var_bp)) # just uniquing gradually to save memory; theoretically need to unique again since there might be repeats from other genes
  }
n_var_bp = length(var_bp) # store denominator
print(n_var_bp)
write.table(results,paste("default_var_bp_from_GTF_results_",sub(".tsv","",gtf_filename),".tsv",sep=""),sep="\t",row.names = F,quote = F)
writefile = file(paste("default_var_bp_from_GTF_n_var_bp_",sub(".tsv","",gtf_filename),".txt",sep=""))
writeLines(as.character(n_var_bp), writefile)
close(writefile)