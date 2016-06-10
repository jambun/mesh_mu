
class MuStore

  def initialize(store)
    @store = store
    @default = nil
    @hash = {}
    @alpha_sorted_keys = []
    @freq_sorted_keys = []
    @longest = 0
    @stale = false
  end

  def add(item)
    @hash[item] ||= @default
    @longest = item.length if item.length > @longest
    @stale = true
    @hash[item]
  end

  def list(sort_by = :alpha)
    if @stale
      if sort_by == :alpha
        @alpha_sorted_keys = @hash.keys.sort
      elsif sort_by == :frequency
        @freq_sorted_keys = @hash.keys.sort { |x,y| @hash[y] <=> @hash[x] }
      end
      @stale = false
    end
    sort_by == :alpha ? @alpha_sorted_keys : @freq_sorted_keys
  end

  def value(item)
    @hash[item]
  end

  def item_value(sort_by = :alpha)
    list(sort_by).each do |item|
      yield ({:item => item, :value => @hash[item]})
    end
  end

  def item_value_pretty(sort_by = :alpha)
    list(sort_by).each do |item|
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

  def list(sort_by = :alpha)
    super.select { |m| m =~ / / }
  end

end

class Mesh < MuStore

  def initialize(store, lexicon)
    super(store)
    @lexicon = lexicon
    @low_items = []
    @default = 0
  end

  def add(item)
    mu = item.split(' ')
    return if mu.length < 2
    lowest = 999999
    lowi = 0
    i = 0

    mu.each do |m|
      if @lexicon.value(m) < lowest
        lowest = @lexicon.value(m)
        lowi = i
      end
      i += 1
    end

    @low_items << mu[lowi]
    mu[lowi] = "[]"
    new_item = mu.join(' ')
    super(new_item)
    @hash[new_item] += 1
#    @hash[new_item] << low_item
#    @hash[new_item].uniq!
  end

  def syntoks
    @lexicon.list - @low_items
  end

end
