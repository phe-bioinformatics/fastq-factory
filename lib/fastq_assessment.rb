module FastqAssessment
  require 'maths'
  FastqStats = Struct.new("FastqStats", :read_position_stats, :mean_quality, :position_where_quality_lt_20, :percentage_compared_to_raw)
  ReadPositionStats = Struct.new("ReadPositionStats", :mean_quality, :median_quality, :first_quartile, :third_quartile)

  def generate_quality_stats_for_read(fastq_file, quality_scale, quality_cutoff = 30)
    fastq_stats = FastqStats.new()
    fastq_stats.read_position_stats = Array.new
    if quality_scale == 64
      qual_stats = `fastx_quality_stats -i #{fastq_file}`
    else
      qual_stats = `fastx_quality_stats -Q 33 -i #{fastq_file}`
    end
    read_positions = qual_stats.split("\n")
    qualities_at_read_positions = Array.new
    read_positions.each do |read_position|
      qual_stats = read_position.split(/\s+/)
      mean_quality = qual_stats[5].to_f
      median_quality = qual_stats[7].to_f
      first_quartile = qual_stats[6].to_f
      third_quartile = qual_stats[8].to_f
      qualities_at_read_positions << mean_quality
      fastq_stats.read_position_stats << ReadPositionStats.new(
        mean_quality,
        median_quality,
        first_quartile,
        third_quartile
        )
    end
    # determine mean quality
    fastq_stats.mean_quality = qualities_at_read_positions.mean
    # determine  position where quality in a 5 position window drops below 20
    position = 0
    qualities_at_read_positions.each_cons(5) do |window|
      position += 1
      if window.mean < quality_cutoff && position > 15
        fastq_stats.position_where_quality_lt_20 = position
        break
      end
    end
    return fastq_stats
  end

  def percentage_compared_to_raw(processed_fastq_file, raw_fastq_file)
    file_lines_processed = `wc -l #{processed_fastq_file}`.split(" ").first.to_f
    file_lines_raw = `wc -l #{raw_fastq_file}`.split(" ").first.to_f
    percentage_reduction = (file_lines_processed/file_lines_raw*100).to_i
  end
end
