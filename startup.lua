while true do
  -- Pause the program until a redstone event happens
  os.pullEvent("redstone")
  
  -- Check if the back of the turtle is receiving a redstone signal
  if redstone.getInput("front") then
    print("Redstone signal DETECTED!")
    turtle.select(1)
    turtle.place()
  end
end
