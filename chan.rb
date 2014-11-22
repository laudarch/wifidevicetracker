require 'concurrent/mvar'

class Chan
  def initialize
    hole   = Concurrent::MVar.new
    @read  = Concurrent::MVar.new( hole )
    @write = Concurrent::MVar.new( hole )
  end

  def readChan
    old      = @read.take
    chanelem = old.take
    @read.put( chanelem.next )
    # return value
    chanelem.value
  end

  def writeChan( value )
    new_hole = Concurrent::MVar.new
    chanelem = ChanElem.new( value, new_hole )
    empty    = @write.take
    empty.put( chanelem )
    @write.put( new_hole )
  end

end

class ChanElem
  attr_accessor :value, :next

  def initialize( v, n )
    self.next  = n
    self.value = v
  end
end