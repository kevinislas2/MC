function bonk () 
  print("bonk")
  turtle.select(2)
  turtle.place()
  turtle.sleep(1)
  turtle.place()
end

local bonked = false

while not bonked do
  local i = math.random(1, 10)
  if i == 1 then
    bonk()
    bonked = true
  end
end
