
class A
  def initialize(s)
    return [s + "-woot", "cow"]
  end
end

a, b, c = A.new("snake")

p a, b, c

def q(s)
  [s + "-woot", "cat"]
end

a, b = q("monkey")
p a, b