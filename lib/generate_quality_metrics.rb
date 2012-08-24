require 'fastq_assessment'
include FastqAssessment
require 'miseq_run_stats'
include MiseqRunStats

def generate_quality_metrics(sample_map, directory, forward_reads_suffix, reverse_reads_suffix, quality_scale, quality_cutoff)
  if File.exists?("#{directory}/ResequencingRunStatistics.xml")
    puts "Assessing quality from Miseq run stats file"
    resequencing_run_stats = parse_resequencing_run_stats("#{directory}/ResequencingRunStatistics.xml", sample_map.values)
  else
    resequencing_run_stats = ResequencingRunStats.new
    resequencing_run_stats.sample_stats = Hash.new
    sample_map.values.each do |sample_name|
      resequencing_run_stats.sample_stats[sample_name] = SampleStats.new
    end
  end


  forward_reads_trimmed_corrected_suffix = forward_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed.cor\2')
  reverse_reads_trimmed_corrected_suffix = reverse_reads_suffix.sub(/(.+)(\..+?)$/, '\1.trimmed.cor\2')


  sample_map.each do |read_file_prefix, sample_name|
    puts "Assesing quality for #{sample_name}"
    resequencing_run_stats.sample_stats[sample_name].fastq_stats = Hash.new
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["forward"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{forward_reads_suffix}",quality_scale, quality_cutoff)
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["reverse"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{reverse_reads_suffix}",quality_scale, quality_cutoff)
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_corrected_suffix}",quality_scale, quality_cutoff)
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["forward-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{forward_reads_trimmed_corrected_suffix}", "#{directory}/#{read_file_prefix}#{forward_reads_suffix}")
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"] = generate_quality_stats_for_read("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_corrected_suffix}",quality_scale, quality_cutoff)
    resequencing_run_stats.sample_stats[sample_name].fastq_stats["reverse-trim_corrected"].percentage_compared_to_raw = percentage_compared_to_raw("#{directory}/#{read_file_prefix}#{reverse_reads_trimmed_corrected_suffix}", "#{directory}/#{read_file_prefix}#{reverse_reads_suffix}")
  end
  # print out data
  output_file = File.open("#{directory}/summary_stats.txt", "w")
  # print headers
  output_file.puts "run name\tnumber of bases(Gb)\tnumber of clusters\tsample name\tdirection\tnumber of clusters\tnumber of forward reads aligned\tnumber of reverse reads aligned\tcoverage\tnumber of snps\tmean quality\tread base where qual falls below 30\tpercent reduction compared to raw"
  output_file.puts "#{directory.match(/.*\/(.+?)$/).captures.first}\t#{resequencing_run_stats.number_of_bases}\t#{resequencing_run_stats.number_of_clusters}"
  resequencing_run_stats.sample_stats.keys.sort.each do |sample_name|
    sample_stats = resequencing_run_stats.sample_stats[sample_name]
    output_file.puts "\t\t\t#{sample_name}\t\t#{sample_stats.number_of_clusters}\t#{sample_stats.number_of_forward_reads_aligned}\t#{sample_stats.number_of_reverse_reads_aligned}\t#{sample_stats.coverage}\t#{sample_stats.number_of_snps}"
    ["forward", "reverse", "forward-trim_corrected", "reverse-trim_corrected"].each do |direction|
      fastq_stats = resequencing_run_stats.sample_stats[sample_name].fastq_stats[direction]
      output_file.puts "\t\t\t\t#{direction}\t\t\t\t\t\t#{fastq_stats.mean_quality}\t#{fastq_stats.position_where_quality_lt_20}\t#{fastq_stats.percentage_compared_to_raw}"
    end
  end
  output_file.close
end