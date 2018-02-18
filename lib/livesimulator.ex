defmodule Livesimulator do
    def start_link(input, spid) do
        GenServer.start_link(__MODULE__, %{:input => input, :server => spid,:followerMap=>%{}},name: {:global, :livesimulator} )
    end

    def init(initial_state) do    
        IO.puts "I am live"
        followerMap=GenServer.call({:global,:simulator},{:getfollowers})
        initial_state = Kernel.put_in(initial_state, [:followerMap],followerMap)
        IO.inspect("I am subscribed to: #{inspect  Enum.reverse(followerMap[initial_state[:input]]) }")
        
        {:ok, initial_state}
    end
    
    def handle_cast({:subscriberTweet, source, tweet, timestamp, retweet, origin}, state) do
      input = state[:input]
      
      followers = Map.get(state[:followerMap],input)
      if( source in followers++[state[:input]] ) do
         
        IO.puts "client #{inspect source} tweeted #{inspect tweet} at time #{inspect timestamp}"    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
      end
        
        {:noreply, state}
    end

end