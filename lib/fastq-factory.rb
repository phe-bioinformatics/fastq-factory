require 'rubygems'
require 'trim_and_correct'
require 'generate_quality_metrics'
def extract_file_prefixes_and_sample_name(sample_map_file, directory)
  sample_map = Hash.new
  File.read("#{directory}/#{sample_map_file}").split("\n").each do |sample_map_line|
    file_prefix, sample_name = sample_map_line.split("\t")
    sample_map[file_prefix] = sample_name
  end
  return sample_map
end

def file_exists?(filename, directory)
  abort("You specified a fastq file : #{filename}. This does not exist! Please check your sample map file") unless File.exists?("#{directory}/#{filename}")
end

def find_executable(executable_name, directory = nil)
  if directory.nil?
    if which(executable_name)
      return which(executable_name)
    elsif File.executable?("/usr/local/bin/#{executable_name}")
      return "/usr/local/bin/#{executable_name}"
    elsif File.executable?("/usr/local/#{executable_name}/#{executable_name}")
      return "/usr/local/#{executable_name}/#{executable_name}"
    else
      return nil
    end
  else
    if File.executable?("#{directory}/#{executable_name}")
      return "#{directory}/#{executable_name}"
    else
      return nil
    end
  end
end

# meethod to return path to command if it is in the path (works in windows)
# @param String cmd the name of the command 
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = "#{path}/#{cmd}#{ext}"
      return exe if File.executable? exe
    }
  end
  return nil
end

def write_out_fastq_trim_script
  system("cp #{File.dirname(__FILE__)}/fastq-remove-orphans.pl /tmp/")
end