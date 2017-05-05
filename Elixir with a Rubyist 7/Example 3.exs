# Let's create a `Sum` module that will have a `sum_number/1`
# funciton.
defmodule Sum do

  # The `sum_number/1` expects one argumento, an integer 
  # that will be used to perform a sum operation  
  def sum_number(x) do

    # Here we use `receive` to match messages into the
    # tuple `{:sum, n}` where `n` is an integer sent
    # with in the message.
    # At this point the process will stop and wait for a 
    # message before trying to match it and move on.
    receive do
      {:sum, n} -> 

        # We display the result of the sum between the number 
        # passed as argument to `sum_number/1` and the number
        # on the received message
        IO.inspect(x + n)

        # Call this function again passing the same argument.
        # By using recursion (calling this function again)
        # we setup the receive block again, waiting for the 
        # next message, so every time a message is received
        # this function will handle it and setup a new receive 
        # block to handle the next one
        sum_number(x)
    end
  end
end

# This will spawn a new process to execute the `sum_number/1`
# function from the `Sum` module we defined above, passing `2`
# as the argument, and will return the PID for this new process
sum_proc = spawn(Sum, :sum_number, [2])
# #PID<0.121.0>


# Then we can send a message for the process we spawn above
# passing the tuple `{:sum, 3}` to check what will be displayed
send(sum_proc, {:sum, 3})
# 5
#
# The number `5` is returned as expected result of `2 + 3`.
# Because the process uses recursion we can still send messages
# to it because it still alive, waiting for another message.

send(sum_proc, {:sum, 10})
# 12

send(sum_proc, {:sum, 6})
# 8

send(sum_proc, {:sum, 2})
# 4

# Here we can check the process is still alive and 
# waiting for messsages
Process.alive?(sum_proc)
# true
