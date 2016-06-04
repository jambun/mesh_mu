require_relative 'mu_store'

class MuImporter

  def initialize(store, tokenizer = nil)
    @store = store
    @tokenizer = tokenizer || WordTokenizer.new(:encoding => 'ISO-8859-1')
    @lexicon = Lexicon.new(store)
    @mus = Mus.new(store)
  end

  def import(readable)
    readable.each_line do |line|
      @tokenizer.tokens_for(line).each do |t|
        @lexicon.add(t)
        @mus.add(t)
      end
    end

    @lexicon.item_value_pretty { |s| puts s }

    @mus.item_value_pretty { |s| puts s }
  end

end

class WordTokenizer

    def initialize(opts)
      @encoding = opts.fetch(:encoding) { 'UTF-8' }
    end

    def tokens_for(line)
      prepared_line = line.encode(@encoding, :invalid => :replace)
      prepared_line.gsub!(/([.,:;?!)])/, ' \1 ')
      prepared_line.gsub!(/(--)/, ' \1 ')
      prepared_line.gsub!(/(\()/, '\1 ')
      prepared_line.gsub!(/(")/, ' \1 ')
      prepared_line.split(/\s+/)
    end
end

