# As you can see the value of `h` is now the first element
# We start greating on Gravatar module
defmodule Gravatar do

  # We'll get into `ensure_all_started/1` on future episodes
  # but here we neet to starte `:inets` app because we will
  # need one of its modules down the road when downloading
  # the gravatar image, `:inets` is part of erlang 
  # standard library
  Application.ensure_all_started(:inets)

  # This is our main function `gravatar_images/1`, it expects
  # a `Map` as argument and this `Map` will store the path
  # for email image we find and download.
  # As you can tell we are using pattern mathcing to ensure
  # the `images_path` argument will be `Map`, this doesn't
  # mean it need to be empty, we coudl start with pre-existing
  # images already.
  def gravatar_images(images_path = %{}) do

    # Here is our receive block, it tries to match messages
    # into three different patterns (all expect to receive
    # also the PID from the process that sent the message): 
    #
    # - {:all_stored_images, pid}
    # - {:get_image, email, pid}
    # - {:store_image, email, path}
    receive do

      # `:all_stored_images` will basically send a message
      # back with all the images by returning the 
      # `images_path` map. 
      # Then it will call `gravatar_images/1` again, passing
      # the same map as argument once again, so we sill have 
      # the receive block ready for the next message.
      {:all_stored_images, pid} ->  
        send(pid, images_path)
        gravatar_images(images_path)

      # `:get_image` will send a message back to the PID that
      # send this message with the local path for that image
      {:get_image, email, pid} ->  

        # `get_image/2` is a private function defined bellow
        # it tries to find the image into the Map we are using
        # as storage, if it doesn't finds, it'll download it
        # and return the path
        new_path = get_image(images_path, email)

        # Here we send the message back with the `new_path`
        # for this image to the process that sent the 
        # initial message
        send(pid, new_path)

        # And then we send a message to this own process but
        # with the tuple `{:store_image, email, new_path}`
        send(self(), {:store_image, email, new_path})

        # We call `gravatar_images/1` once again because we
        # need to setup a new `receive` block to handle the
        # previous message we just sent with the 
        # `:store_image` tuple.
        gravatar_images(images_path)

      # `:store_image` will update the email key on the map
      # we are using as storage to store the local path for
      # the image.
      # Using the pipe operator we call `gravatar_images/1`
      # function again, but now passing the new Map as the
      # arguments, and that's what enable us to hold state
      # and having a in-memory storage.
      {:store_image, email, path} ->  
        Map.put(images_path, email, path)
        |> gravatar_images
    end
  end

  # The functions bellow are related to the gravatar 
  # integration, I'll avoind getting deep into explaning 
  # what is going on because it's not the main subject for
  # this example
  defp get_image(images_path, email) do
    # Tries to get the `email` key from the map, if there
    # is none key with that value, then call `download_image`.
    # here we are using case with pattern mathing, we talked
    # about it in later episodes already.
    case Map.get(images_path, email, :not_found) do
      :not_found -> download_image(email)
      path -> path
    end
  end

  # Request, download and write the file to our local env
  # return the path as the function response.
  defp download_image(email) do
    path = "gravatar/#{email}.jpg"
    file = gravatar_file(email)
    File.write!(path, file)
    path
  end

  # Returns the binary of the image from gravatar API.
  defp gravatar_file(email) do
    http_opts = [body_format: :binary]
    url_data = {gravatar_url(email), []}
    
    {:ok, resp} = :httpc.request(:get, url_data, [], http_opts)
    {{_, 200, 'OK'}, _headers, body} = resp
    body
  end

  # Mounts the gravatar API url accordinly to 
  # their docs.
  defp gravatar_url(email) do
    email_hash = :crypto.hash(:md5, email) 
    |> Base.encode16(case: :lower)
    'http://www.gravatar.com/avatar/#{email_hash}.jpg'
  end
end


# First we create spaw a new process, that will execute
# the `gravatar_images/1` method from the `Gravatar`
# module we just created, seding and empty map (`%{}`)
# as argument.
pid = spawn(Gravatar, :gravatar_images, [%{}])

# Now we can send this process a message to get the 
# avatar picture for my email
send(pid, {:get_image, "me@joaomdmoura.com", self()})

# If we check the messages our current interactive
# console has, we are supposed to have a new one with
# the local path for the image we just requested
:erlang.process_info(self(), :messages)
# {:messages, ["gravatar/me@joaomdmoura.com.jpg"]}
#
# As you can see, we do have a new message with the 
# local path for that image

# If we ask for all images stored so far it will
# shoot a new message back, now with the whole map
send(pid, {:all_stored_images, self()})

:erlang.process_info(self(), :messages)
# {:messages,
#  ["gravatar/me@joaomdmoura.com.jpg",
#   %{"me@joaomdmoura.com" => "gravatar/me@joaomdmoura.com.jpg"}]}
#
# Now we have two messages, the last one and a new 
# one with a map that has an email as a key and the
# path as value.
