require_relative 'src/mu_importer'

def show_usage
  raise "Usage: #{$0} file"
end

$file = ARGV.fetch(0) { show_usage }

def main
  store = 1
  importer = MuImporter.new(store)
  File.open($file, 'r') do |fh|
    importer.import(fh)
  end
end

main

