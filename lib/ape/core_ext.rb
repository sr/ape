# http://blog.moertel.com/articles/2007/02/07/ruby-1-9-gets-handy-new-method-object-tap
class Object
  def tap
    yield(self)
    self
  end
end

class Symbol
  def to_proc 
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end
end
