require "linalg"
include LA

def print_vec(vec)
  print "#{vec.x},#{vec.y},#{vec.z}"
end

abstract class Attractor
  getter current : Vector3
  getter history : Array(Vector3)

  def initialize(initial = Vector3.new(1.0))
    @current = initial
    @history = [initial]
  end

  def step(t = 0.01)
    @current += dot * t
    @history << @current
  end

  abstract def dot : Float64
end

class Lorenz < Attractor
  @a : Float64
  @b : Float64
  @c : Float64

  def initialize(@a = 10.0, @b = 28.0, @c = (8.0/3.0),
                 initial = Vector3.new(1.0))
    super(initial)
  end

  def dot
    x, y, z = @current.x, @current.y, @current.z

    Vector3.new(
      @a*(y - x),
      x*(@b - z) - y,
      x*y - @c*z
    )
  end
end

class Arneodo < Attractor
  @a : Float64
  @b : Float64
  @d : Float64

  def initialize(@a = -5.5, @b = 3.5, @d = -1.0,
                 initial = Vector3.new(1.0))
    super(initial)
  end

  def dot
    x, y, z = @current.x, @current.y, @current.z

    Vector3.new(
      y,
      z,
      -@a*x - @b*y - z + @d*x*x*x
    )
  end
end

a = Lorenz.new
# a = Arneodo.new

length = 2000 * 0.01
step_size = 0.004

(length / step_size).to_i.times do
  a.step(step_size)
end

rects = [] of Array(Vector3)

data = a.history
data.each_cons(2) do |line|
  a, b = line

  dir = (b - a).normalize
  w = dir.x > 0.9 ? Vector3.new(0.0, 1.0, 0.0) : Vector3.new(1.0, 0.0, 0.0)

  u = dir.cross(w).normalize
  v = dir.cross(u)

  size = 1.0

  rect = [
    a,
    a + u * size,
    a + u * size + v * size,
    a + v * size,
  ]

  rects << rect
end

def to_triangles(rect1, rect2)
  a, b, c, d = rect1
  a_, b_, c_, d_ = rect2

  [
    [a, a_, b_],
    [b, b_, c_],
    [c, c_, d_],
    [d, d_, a_],
    [a, b, b_],
    [b, c, c_],
    [c, d, d_],
    [d, a, a_],
  ]
end

triangles = [] of Array(Vector3)

rects.each_cons(2) do |rect12|
  rect1, rect2 = rect12
  triangles += to_triangles(rect1, rect2)
end

max_x = -Float64::MAX
min_x = Float64::MAX
max_y = -Float64::MAX
min_y = Float64::MAX
max_z = -Float64::MAX
min_z = Float64::MAX

triangles.each do |triangle|
  triangle.each do |p|
    max_x = {p.x, max_x}.max
    max_y = {p.y, max_y}.max
    max_z = {p.z, max_z}.max

    min_x = {p.x, min_x}.min
    min_y = {p.y, min_y}.min
    min_z = {p.z, min_z}.min
  end
end

max = Vector3.new(max_x, max_y, max_z)
min = Vector3.new(min_x, min_y, min_z)

center = (max + min) * 0.5

max = max - center
min = min - center

size = 10.0

max_extend = {max_x, max_y, max_z, -min_x, -min_y, -min_z}.max
inv_extend = size / max_extend

triangles.each do |triangle|
  a, b, c = triangle

  print_vec((a - center) * inv_extend)
  print ","
  print_vec((b - center) * inv_extend)
  print ","
  print_vec((c - center) * inv_extend)
  print "\n"
end
