module MiseqRunStats
  require 'nokogiri'
  ResequencingRunStats = Struct.new("ResequencingRunStats", :number_of_bases, :number_of_clusters, :sample_stats)
  ResequencingSampleStats = Struct.new("ResequencingSampleStats", :sample_name, :number_of_clusters, :number_of_forward_reads_aligned, :number_of_reverse_reads_aligned, :coverage, :number_of_snps, :fastq_stats)
  AssemblyRunStats = Struct.new("AssemblyRunStats", :number_of_bases, :number_of_clusters, :sample_stats)
  AssemblySampleStats = Struct.new("AssemblySampleStats", :sample_name, :number_of_clusters, :number_of_contigs, :mean_contig_size, :n50, :number_of_bases, :fastq_stats)
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

      resequencing_run_stats.sample_stats[sample_name] = ResequencingSampleStats.new
      resequencing_run_stats.sample_stats[sample_name].sample_name = sample_name
      resequencing_run_stats.sample_stats[sample_name].number_of_clusters = summarised_samples_stats.search('NumberOfClustersPF').text
      resequencing_run_stats.sample_stats[sample_name].number_of_forward_reads_aligned = summarised_samples_stats.search('ClustersAlignedR1').text
      resequencing_run_stats.sample_stats[sample_name].number_of_reverse_reads_aligned = summarised_samples_stats.search('ClustersAlignedR2').text
      resequencing_run_stats.sample_stats[sample_name].coverage = summarised_samples_stats.search('WeightedCoverage').text
      resequencing_run_stats.sample_stats[sample_name].number_of_snps = summarised_samples_stats.search('NumberHomozygousSNPs').text
    end
    return resequencing_run_stats
  end
  def parse_assembly_run_stats(xml_file, original_sample_names = nil)
    xml = Nokogiri::XML(File.read(xml_file))
    assembly_run_stats = AssemblyRunStats.new

    xml.search('//RunStats').each do |run_stats|
      assembly_run_stats.number_of_bases = run_stats.search('YieldInBasesPF').text.to_f/1000000000
      assembly_run_stats.number_of_clusters = run_stats.search('NumberOfClustersPF').text.to_i
    end

    # get un-named contig data
    assembly_stats = Array.new
    xml.search('//AssemblyStatistics').each do |assembly_sample_stats|
      number_of_contigs = assembly_sample_stats.search('NumberOfContigs').text.to_i
      mean_contig_size = assembly_sample_stats.search('MeanContigLength').text.to_f.to_i
      n50 = assembly_sample_stats.search('N50').text.to_i
      number_of_bases = assembly_sample_stats.search('BaseCount').text.to_i
      assembly_stats << {:number_of_contigs  => number_of_contigs, :mean_contig_size => mean_contig_size, :n50 => n50, :number_of_bases => number_of_bases}
    end

    assembly_run_stats.sample_stats = Hash.new
    xml.search('//SampleStatistics').each do |sample_stats|
      sample_name = sample_stats.search('SampleName').text
      sample_name = original_sample_names.select{|original_sample_name| sample_name =~ /#{original_sample_name}/}.first unless original_sample_names.nil? # alter sample name to original sample name if supplies as an array
      next if sample_name.nil?

      assembly_run_stats.sample_stats[sample_name] = AssemblySampleStats.new
      assembly_run_stats.sample_stats[sample_name].sample_name = sample_name
      assembly_run_stats.sample_stats[sample_name].number_of_clusters = sample_stats.search('NumberOfClustersPF').text
      assembly_sample_stats = assembly_stats.shift
      assembly_run_stats.sample_stats[sample_name].number_of_contigs = assembly_sample_stats[:number_of_contigs]
      assembly_run_stats.sample_stats[sample_name].mean_contig_size = assembly_sample_stats[:mean_contig_size]
      assembly_run_stats.sample_stats[sample_name].n50 = assembly_sample_stats[:n50]
      assembly_run_stats.sample_stats[sample_name].number_of_bases = assembly_sample_stats[:number_of_bases]
 
    end
    return assembly_run_stats
  end
end