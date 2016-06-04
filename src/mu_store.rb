
class MuStore

  def initialize(store)
    @store = store
    @default = nil
    @hash = {}
    @sorted_keys = []
    @longest = 0
    @stale = false
  end

  def add(item)
    @hash[item] ||= @default
    @longest = item.length if item.length > @longest
    @stale = true
    @hash[item]
  end

  def list
    if @stale
      @sorted_keys = @hash.keys.sort
      @stale = false
    end
    @sorted_keys
  end

  def item_value
    list.each do |item|
      yield ({:item => item, :value => @hash[item]})
    end
  end

  def item_value_pretty
    list.each do |item|
      yield (item + (" " * (@longest-item.length+2)) + @hash[item].to_s)
    end
  end

end


class Lexicon < MuStore

  def initialize(store)
    super
    @default = 0
  end

  def add(item)
    super
    @hash[item] += 1
  end

end


class Mus < MuStore

  def initialize(store)
    super
    @mu = []
  end

  def add(item)
    @mu << item
    mus = @mu.join(' ')

    if @hash[mus]
      @hash[mus] += 1
    else
      super(mus)
      @hash[mus] = 1
      @mu = []
    end

    @hash[mus]
  end

end

