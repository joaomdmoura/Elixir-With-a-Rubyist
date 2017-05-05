# Let's start by figuring out out console Process ID (PID)
# by now you already now that all you need to stat the
# interactive console is to type `iex` on the terminal.


# The `self/0` function return the current Process PID.
current_proc = self()
# #PID<0.56.0>


# Now we can use the `process_info/2` function
# from erlang to get all messages our current
# process (the interactive console) has
:erlang.process_info(self(), :messages)
# {:messages, []}
# As you can see, there are no messages waiting.


# We can send a message from this process to itself by
# using the `send/2` function, it has two arguments, the
# PID and the message.
send(current_proc, "new message")


# Now, if we check our current process message we will
# find one message waiting to be dealt with.
:erlang.process_info(self(), :messages)
# {:messages, ["new message"]}


# To handle messages we need to use a receive block
# it's really straightforward and uses pattern matching
# against the next message on the list.
receive do
  message -> IO.inspect("Received #{message}")
end
# "Received new message"
#
# The message is displayed and now if we check the list
# of messages, it should be empty again

:erlang.process_info(self(), :messages)
# {:messages, []}
