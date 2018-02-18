defmodule Client do
    use GenServer
    #Initiate GenServer
    def start_link(spid, rank) do
      GenServer.start_link(__MODULE__, %{ :server => spid, :rank => rank})
    end
  
    #Set the initial state of client
    def init(initial_state) do
        {:ok,initial_state}
    end
    
    def set_subcriber(s,pid) do
        GenServer.cast(pid, {:setSubscribers, s})
    end


    def handle_cast({:setSubscribers, s},state) do
        #IO.puts "I am inside set neighbour"
        state = Map.put(state, :subscriber,s)
        
        {:noreply,state}
    end

 
    def handle_call({:state},_from,state) do
        #IO.puts("client state #{inspect state}")
        {:reply, state, state}
    end

    def handle_cast({:startFollowers, num_followers, noOfUsers}, state) do
        follower_list = Enum.reduce(1..num_followers, [], fn _, acc ->
            acc = acc ++ [Util.pickRandom(noOfUsers, state[:rank])]
        end)

        state = Map.put(state, :num_followers, num_followers)
        state = Map.put(state, :noOfUsers, noOfUsers)
        
        #Server.set_subcriber(state[:server], state[:rank], follower_list)
        GenServer.cast(state[:server], {:setFollowers, state[:rank], follower_list})
        {:noreply, state}
    end

    def handle_info({:tweet}, state) do
        mentions = Enum.map(1..1, fn _ -> 
            s = Util.generate(state[:noOfUsers], state[:rank]) |> Integer.to_string
            "@"<>s
        end)
        hashtag=Enum.random(["aa","bb","cc","dd","ee","ff","gg","hh","ii","jj","kk","ll","mm","nn","oo","pp","qq","rr","ss","tt","uu","vv","ww","xx","yy","zz"])
        hashtag="#"<>hashtag<>" "
        timestamp = :os.system_time(:milli_seconds)
        randomTweet = "Hello1 hi1 "<>hashtag<> Enum.join(mentions, " ") 
        #IO.puts "client #{inspect source} tweeted #{inspect tweet} at time #{inspect timestamp}"

        response = GenServer.call(state[:server], {:tweet, state[:rank], randomTweet, timestamp, false, nil})
        Process.send_after(self(), {:tweet}, state[:rank]*10000)

        {:noreply, state}
    end

    def handle_info({:startTweeting}, state) do
        Process.send_after(self(), {:tweet}, state[:rank]*100)
        {:noreply, state}
    end

    def handle_cast({:subscriberTweeted,  source, tweet, timestamp, retweet, origin }, state) do
        retweetFlag = Enum.random([true, false])
        IO.puts "client #{inspect source} tweeted #{inspect tweet} at time #{inspect timestamp}"
         GenServer.cast({:global ,:livesimulator}, {:subscriberTweet, source, tweet, timestamp, retweet, origin})
        if retweetFlag do 
            IO.puts "client #{inspect source} retweeted #{inspect tweet} at time #{inspect timestamp}"
            GenServer.call(state[:server], {:tweet, state[:rank], tweet, timestamp, retweetFlag, source})
        end
      
        {:noreply, state}
    end

    
end