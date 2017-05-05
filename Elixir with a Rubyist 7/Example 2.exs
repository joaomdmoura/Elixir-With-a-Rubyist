current_proc = self()
# #PID<0.56.0>


:erlang.process_info(self(), :messages)
# {:messages, []}
# No messages waiting.


# This time we sen mutiple messages to this same process
# we will send tuples, with a `:new_message` atom and
# an integer
send(current_proc, {:new_message, 1})
send(current_proc, {:new_message, 2})
send(current_proc, {:new_message, 3})


# On our messages list we'll find all three messages
:erlang.process_info(self(), :messages)
# {:messages, [new_message: 1, new_message: 2, new_message: 3]}


# Now we use the `receive` block to pattern match the
# tuple with `{:new_message, n}`, and then display a message
# indicating we got the message
receive do
  {:new_message, n} -> IO.inspect("Received new message: #{n}")
end
# "Received new message: 1"
# 
# Only the first message was handled, the other two
# are still in the list waiting for another 
# receive block

:erlang.process_info(self(), :messages)
# {:messages, [new_message: 2, new_message: 3]}


