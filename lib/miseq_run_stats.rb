module MiseqRunStats
  require 'nokogiri'
  ResequencingRunStats = Struct.new("ResequencingRunStats", :number_of_bases, :number_of_clusters, :sample_stats)
  SampleStats = Struct.new("SampleStats", :sample_name, :number_of_clusters, :number_of_forward_reads_aligned, :number_of_reverse_reads_aligned, :coverage, :number_of_snps, :fastq_stats)
  def parse_resequencing_run_stats(xml_file, original_sample_names = nil)
    xml = Nokogiri::XML(File.read(xml_file))
    resequencing_run_stats = ResequencingRunStats.new

    xml.search('//RunStats').each do |run_stats|
      resequencing_run_stats.number_of_bases = run_stats.search('YieldInBasesPF').text.to_f/1000000000
      resequencing_run_stats.number_of_clusters = run_stats.search('NumberOfClustersPF').text.to_i
    end

    resequencing_run_stats.sample_stats = Hash.new
    xml.search('//SummarizedSampleStatisics').each do |summarised_samples_stats|
      sample_name = summarised_samples_stats.search('SampleName').text
      sample_name = original_sample_names.select{|original_sample_name| sample_name =~ /#{original_sample_name}/}.first unless original_sample_names.nil? # alter sample name to original sample name if supplies as an array

      resequencing_run_stats.sample_stats[sample_name] = SampleStats.new
      resequencing_run_stats.sample_stats[sample_name].sample_name = sample_name
      resequencing_run_stats.sample_stats[sample_name].number_of_clusters = summarised_samples_stats.search('NumberOfClustersPF').text
      resequencing_run_stats.sample_stats[sample_name].number_of_forward_reads_aligned = summarised_samples_stats.search('ClustersAlignedR1').text
      resequencing_run_stats.sample_stats[sample_name].number_of_reverse_reads_aligned = summarised_samples_stats.search('ClustersAlignedR2').text
      resequencing_run_stats.sample_stats[sample_name].coverage = summarised_samples_stats.search('WeightedCoverage').text
      resequencing_run_stats.sample_stats[sample_name].number_of_snps = summarised_samples_stats.search('NumberHomozygousSNPs').text
    end
    return resequencing_run_stats
  end
end