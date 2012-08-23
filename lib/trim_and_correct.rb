def trim_and_correct_fastqs(sample_map, directory, forward_reads_suffix, forward_reads_file_extension, reverse_reads_suffix, reverse_reads_file_extension, quality_scale, fastq_quality_trimmer_path, quake_path)
  Dir.chdir(directory)
  # trimming
  sample_map.each do |sample_file_prefix, sample_name|
    puts "Trimming files for #{sample_name}"

    system("#{fastq_quality_trimmer_path} -i #{directory}/#{sample_file_prefix}#{forward_reads_suffix}.#{forward_reads_file_extension} -o #{directory}/#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} -t 20 -l 90 -Q #{quality_scale} -v")
    system("#{fastq_quality_trimmer_path} -i #{directory}/#{sample_file_prefix}#{reverse_reads_suffix}.#{reverse_reads_file_extension} -o #{directory}/#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension} -t 20 -l 90 -Q #{quality_scale} -v")
    system("perl /tmp/fastq-remove-orphans.pl -1 #{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} -2 #{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
  end

  #  quake correction
  # write file for quake
  sample_map.each do |sample_file_prefix, sample_name|
    output_file = File.open("quake_file_list.txt","w")
    output_file.puts "paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}"
    output_file.close
    # run quake
    system("#{quake_path} -f quake_file_list.txt -k 15 -q #{quality_scale}")
  end
  sample_map.each do |sample_file_prefix, sample_name|
    system("perl /Volumes/NGS2_DataRAID/projects/MRSA/scripts/fastq-remove-orphans.pl -1 paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension} -2 paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
  end

  # cleanup and rename files
  sample_map.each do |sample_file_prefix, sample_name|
    system("rm #{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
    system("rm #{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
    system("rm paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
    system("rm paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
    system("rm orphaned_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
    system("rm orphaned_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
    system("rm error_model.paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.txt")
    system("rm error_model.paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.txt")
    system("rm paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.stats.txt")
    system("rm paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor_single.#{forward_reads_file_extension}")
    system("rm paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.stats.txt")
    system("rm paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor_single.#{forward_reads_file_extension}")
    system("rm paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
    system("rm paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
    system("rm orphaned_paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
    system("rm orphaned_paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
    system("mv paired_paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension} #{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
    system("mv paired_paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension} #{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
  end
end