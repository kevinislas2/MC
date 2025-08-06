function bonk () 
  print("bonk")
  turtle.select(1)
  turtle.place()
end

local bonked = false

while not bonked do
  local i = math.random(1, 10000)
  if i == 500 then
    bonk()
    bonked = true
  end
end
