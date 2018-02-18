defmodule MainServer do
    @loadfactor 100
    @noOfAlphabets 26

    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, nil)
    end

    def init(_) do
        IO.puts "server started"     
        initial_state = %{ :noOfClients => 0,  :counter => 0,:followers => %{}}

    {:ok, initial_state}
    end

    def handle_cast({:noOfClients, noOfClients}, state) do
        IO.puts "creating processors, data stores and hashtag stores to scale"

        state = Map.put(state, :noOfClients, noOfClients)  
    
        noOfServers =  noOfClients / @loadfactor |> round
    
        servers = Enum.reduce(0..noOfServers, %{}, fn i, acc -> 
            {:ok, serverId} = GenServer.start_link(Server, :ok)
            {:ok, datacentreId} = GenServer.start_link(DataCentre, :ok)
      
        Map.put(acc, i, [server: serverId, datacentre: datacentreId])
        end)

        hashtagCentres = Enum.reduce(0..@noOfAlphabets-1, %{}, fn i, acc ->
          {:ok, hashtag_centre} = GenServer.start_link(HashtagCentre, servers) 
        Map.put(acc, <<97 + i >>, hashtag_centre)
        end)

        Enum.each(0..noOfServers, fn id ->
            GenServer.cast(servers[id][:server], {:initialize, servers, hashtagCentres, servers[id][:datacentre], @loadfactor}) 
        end)

        state = Map.put(state, :servers, servers)
        state = Map.put(state, :hashtagCentres, hashtagCentres)
    
    {:noreply, state}
    end
    # get no of clients and to load balance create those many workers

    #register_users
    def handle_cast({:setUser, rank, pid}, state) do
        serverId = rank / @loadfactor |> round 
        GenServer.cast(state[:servers][serverId][:datacentre], {:setUser, rank, pid})
        noOfServers =  state[:noOfClients] / @loadfactor |> round
        Enum.each(0..noOfServers, fn id ->
            GenServer.cast(state[:servers][serverId][:server], {:setusers, rank, pid}) 
        end)
        {:noreply, state}  
    end

     def handle_cast({:setNumUsers, noOfUsers}, state) do
        state = Kernel.put_in(state,[:noOfClients],noOfUsers)
        {:noreply, state}  
    end


     def handle_call({:tweet, rank, tweet, timestamp, retweet, origin}, _from, state) do
        serverId =  rank / @loadfactor |> round 
        GenServer.cast(state[:servers][serverId][:server], {:tweet, rank, tweet, timestamp, retweet, origin})

        {:reply, {"tweet call acknowledge"}, state}
     end
    #setFollowers

    def handle_cast({:setFollowers, rank, followers}, state) do
        serverId = rank / @loadfactor |> round 
        
        noOfServers =  state[:noOfClients] / @loadfactor |> round
        
        Enum.each(0..noOfServers, fn id ->
            GenServer.cast(state[:servers][serverId][:server], {:setfollowers, rank, followers}) 
        end)
        GenServer.cast(state[:servers][serverId][:datacentre], {:followers, rank, followers})
       # IO.puts("user #{rank} follower #{followers}")
         {_, state} = Map.get_and_update(state, :counter, fn x -> {x, x + 1} end)
       
       if followers != nil do
       state = Kernel.put_in(state, [:followers, rank], followers)
       end 
    if state[:counter] == state[:noOfClients] do
      IO.puts "done creating follower relations, network will now start tweeting" 
      GenServer.cast({:global,:simulator},{:setfollowers,state[:followers]})
      GenServer.cast({:global, :simulator}, {:startTweeting})
    end

    {:noreply, state}  
  end
    
    def handle_call({:queryMention,mention},_from,state )do
        IO.puts "I am in main server"
        serverId = mention / @loadfactor |> round
        IO.inspect(state[:servers][serverId][:datacentre]) 
        GenServer.cast(state[:servers][serverId][:datacentre], {:getmentioned, mention,self()})
       
    {:reply,state,state} 
    end 

    def handle_call({:queryHashtag,hashtag},_from,state )do
        IO.puts "I am in main server"
        htc = String.slice(hashtag, 0..0)
        IO.puts(htc)
        IO.inspect(state[:hashtagCentres]) 

        GenServer.cast(state[:hashtagCentres][htc], {:gethashtag, hashtag,self()})
    {:reply,state,state} 
    end 
    

    def handle_cast({:receivedmentioned,mentioned},state) do
        GenServer.cast({:global, :querysimulator},{:receivedMentioned,mentioned})
        {:noreply,state}
    end
   
    def handle_cast({:livestatus,source, tweet, timestamp, retweet, origin},state) do
         GenServer.cast({:global ,:livesimulator}, {:subscriberTweet, source, tweet, timestamp, retweet, origin,state[:followers]})
        {:noreply,state}
    end

    def handle_call({:getfollowers},_from,state )do
       
    {:reply,state[:followers],state} 
    end 

end