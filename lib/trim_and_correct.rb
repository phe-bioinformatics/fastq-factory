def trim_and_correct_fastqs(sample_map, directory, forward_reads_suffix, forward_reads_file_extension, reverse_reads_suffix, reverse_reads_file_extension, quality_scale, fastq_quality_trimmer_path, quake_path,trim_point_fraction, trim_quality_cutoff)
  Dir.chdir(directory)
  # trimming
  # sample_map.each do |sample_file_prefix, sample_name|
  #   next if File.exists?("#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}") || File.exists?("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
  #   puts "Trimming files for #{sample_name}"
  #   #determine read length
  #   read_length = calculate_read_length("#{directory}/#{sample_file_prefix}#{forward_reads_suffix}.#{forward_reads_file_extension}")
  #   trim_point = (trim_point_fraction * read_length).to_i
  #   unless File.exists?("#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
  #     `#{fastq_quality_trimmer_path} -i #{directory}/#{sample_file_prefix}#{forward_reads_suffix}.#{forward_reads_file_extension} -o #{directory}/#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} -t #{trim_quality_cutoff} -l #{trim_point} -Q #{quality_scale} -v`
  #     `#{fastq_quality_trimmer_path} -i #{directory}/#{sample_file_prefix}#{reverse_reads_suffix}.#{reverse_reads_file_extension} -o #{directory}/#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension} -t #{trim_quality_cutoff} -l #{trim_point} -Q #{quality_scale} -v`
  #   end
  #   `perl /tmp/fastq-remove-orphans.pl -1 #{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} -2 #{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}`
  # end

  # #  quake correction
  # # write file for quake
  # sample_map.each do |sample_file_prefix, sample_name|
  #   next if File.exists?("#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}") || File.exists?(("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}"))
  #   puts "Error correcting files for #{sample_name}"
  #   output_file = File.open("quake_file_list.txt","w")
  #   output_file.puts "paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension} paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}"
  #   output_file.close
  #   # run quake
  #   `#{quake_path} -f quake_file_list.txt -k 15 -q #{quality_scale}`
  # end
  # sample_map.each do |sample_file_prefix, sample_name|
  #   next if File.exists?("#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
  #   # remove orphans
  #   `perl /tmp/fastq-remove-orphans.pl -1 paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension} -2 paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}`
  # end

  # cleanup and rename files

  sample_map.each do |sample_file_prefix, sample_name|
    delete_file_with_dependencies("#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}", "#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
    delete_file_with_dependencies("#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}", "#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
    delete_file_with_dependencies("orphaned_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
    delete_file_with_dependencies("orphaned_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
    if File.exists?("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
      delete_file_with_dependencies("error_model.paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.txt")
      delete_file_with_dependencies("error_model.paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.txt")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.stats.txt")
      delete_file_with_dependencies"paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor_single.#{forward_reads_file_extension}")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.stats.txt")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor_single.#{forward_reads_file_extension}")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
      delete_file_with_dependencies("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
      delete_file_with_dependencies("orphaned_paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
      delete_file_with_dependencies("orphaned_paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
      File.rename("paired_paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}", "#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}") if File.exists?("paired_paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.cor.#{forward_reads_file_extension}")
      File.rename("paired_paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}", "#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}") if File.exists?("paired_paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.cor.#{reverse_reads_file_extension}")
    else
      File.rename("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}", "#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}") if File.exists?("paired_#{sample_file_prefix}#{forward_reads_suffix}.trimmed.#{forward_reads_file_extension}")
      File.rename("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}", "#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}") if File.exists?("paired_#{sample_file_prefix}#{reverse_reads_suffix}.trimmed.#{reverse_reads_file_extension}")
    end
  end
end

def delete_file_with_dependencies(file, *dependencies)
  dependencies << file
  if dependencies.all?{|dependency| File.exists?(dependency)} && File.exists?(file)
    File.delete(file)
  end
end

def calculate_read_length(filename)
  read_length = nil
  File.open(filename) do |f|
    f.each do |line|
     line.chomp!
     if line =~ /^[GATCgatc]/
       read_length = line.size
       break
     end
    end
  end
  return read_length - 1
end