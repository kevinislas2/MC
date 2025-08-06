function bonk () 
  print("bonk")
  turtle.select(2)
  turtle.place()
end
while true do
  local i = math.random(1, 10)
  if i == 1 then
    bonk()
  end
end
