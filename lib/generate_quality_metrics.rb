require 'fastq_assessment'
include FastqAssessment
require 'miseq_run_stats'
include MiseqRunStats

def generate_quality_metrics(sample_map, directory, forward_reads_suffix, reverse_reads_suffix, quality_scale, quality_cutoff)
  if File.exists?("#{directory}/ResequencingRunStatistics.xml")
    puts "Assessing quality from Miseq run stats file"
    run_stats = parse_resequencing_run_stats("#{directory}/ResequencingRunStatistics.xml", sample_map.values)
  elsif File.exists?("#{directory}/AssemblyRunStatistics.xml")
    puts "Assessing quality from Miseq run stats file"
    run_stats = parse_assembly_run_stats("#{directory}/AssemblyRunStatistics.xml", sample_map.values)
  else
    run_stats = ResequencingRunStats.new
    run_stats.sample_stats = Hash.new
    sample_map.values.each do |sample_name|
      run_stats.sample_stats[sample_name] = ResequencingSampleStats.new
    end
  end

  forward_reads_trimmed_suffix = forward_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed\2')
  reverse_reads_trimmed_suffix = reverse_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed\2')

  forward_reads_trimmed_corrected_suffix = forward_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed.cor\2')
  reverse_reads_trimmed_corrected_suffix = reverse_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed.cor\2')

  sample_map.each do |read_file_prefix, sample_name|
    puts "Assesing quality for #{sample_name}"
    run_stats.sample_stats[sample_name].fastq_stats = Hash.new
    run_stats.sample_stats[sample_name].fastq_stats["forward"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{forward_reads_suffix}",quality_scale, quality_cutoff)
    run_stats.sample_stats[sample_name].fastq_stats["reverse"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{reverse_reads_suffix}",quality_scale, quality_cutoff)
    if File.exists?("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_corrected_suffix}")
      run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_corrected_suffix}",quality_scale, quality_cutoff)
      run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_corrected_suffix}", "#{directory}/#{read_file_prefix}#{forward_reads_suffix}")
      run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_corrected_suffix}",quality_scale, quality_cutoff)
      run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_corrected_suffix}", "#{directory}/#{read_file_prefix}#{reverse_reads_suffix}")
    else
      run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_suffix}",quality_scale, quality_cutoff)
      run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_suffix}", "#{directory}/#{read_file_prefix}#{forward_reads_suffix}")
      run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_suffix}",quality_scale, quality_cutoff)
      run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_suffix}", "#{directory}/#{read_file_prefix}#{reverse_reads_suffix}")
    end

  end
  # print out data
  output_file = File.open("#{directory}/summary_stats.txt", "w")
  # print headers
  output_file.puts "run name\tnumber of bases(Gb)\tnumber of clusters\tsample name\tdirection\tnumber of clusters\tnumber of forward reads aligned\tnumber of reverse reads aligned\tcoverage\tnumber of snps\tnumber of contigs\tmean contig size\tn50\tnumber of bases\tmean quality\tread base where qual falls below 30\tpercent reduction compared to raw"
  output_file.puts "#{directory.match(/.*\/(.+?)$/).captures.first}\t#{run_stats.number_of_bases}\t#{run_stats.number_of_clusters}"
  run_stats.sample_stats.keys.sort.each do |sample_name|
    sample_stats = run_stats.sample_stats[sample_name]
    if sample_stats.class == Struct::ResequencingSampleStats
      output_file.puts "\t\t\t#{sample_name}\t\t#{sample_stats.number_of_clusters}\t#{sample_stats.number_of_forward_reads_aligned}\t#{sample_stats.number_of_reverse_reads_aligned}\t#{sample_stats.coverage}\t#{sample_stats.number_of_snps}"
    elsif sample_stats.class == Struct::AssemblySampleStats
      output_file.puts "\t\t\t#{sample_name}\t\t#{sample_stats.number_of_clusters}\t\t\t\t\t#{sample_stats.number_of_contigs}\t#{sample_stats.mean_contig_size}\t#{sample_stats.n50}\t#{sample_stats.number_of_bases}"
    end
    ["forward", "reverse", "forward-trim_corrected", "reverse-trim_corrected"].each do |direction|
      fastq_stats = run_stats.sample_stats[sample_name].fastq_stats[direction]
      output_file.puts "\t\t\t\t#{direction}\t\t\t\t\t\t\t\t\t\t#{fastq_stats.mean_quality}\t#{fastq_stats.position_where_quality_lt_20}\t#{fastq_stats.percentage_compared_to_raw}"
    end
  end
  output_file.close
end