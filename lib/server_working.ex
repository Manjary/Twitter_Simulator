defmodule Server_working do
    use GenServer
    #Initiate GenServer
    def start_link() do
      s="server"                
      test=GenServer.start_link(__MODULE__,s,name: {:global, :server})
      IO.inspect(test)
    end
  
    #Set the initial state of server
    def init(s) do
        state= %{:pid=>self(),:user=>%{},:usertweets => %{},:tweets => %{}, :subscribers => %{},:hashtags => %{}, :mentions => %{}}
        IO.inspect(state)
        {:ok,state}
    end

    #set user of the server  
    def set_user(s,pid) do
        GenServer.cast(pid, {:setUser, s})
    end

    def handle_cast({:setUser, s},state) do
        state = Kernel.put_in(state, [:user, List.first(s)], List.last(s))
        {:noreply, state}
    end

    def handle_cast({:setNumUsers, noOfUsers, sid}, state) do
        state = Map.put(state, :noOfUsers, noOfUsers)
        state = Map.put(state, :simulator, sid)

        {:noreply, state}
    end

    #set subsriber of the user
    def set_subcriber(spid, rank, follower_list) do
        GenServer.cast(spid, {:setSubscribers, rank, follower_list})
    end


    def handle_cast({:setSubscribers, rank, follower_list},state) do
        state = Kernel.put_in(state, [:subscribers, rank], follower_list)
        IO.inspect state[:subscribers]

        if(length(Map.keys(state[:subscribers])) == state[:noOfUsers]) do
            IO.puts "start tweeting"
            IO.inspect state[:simulator]
            GenServer.cast(state[:simulator], {:startTweeting})
        end
        
        {:noreply, state}
    end

    def get_server_state(pid) do
        GenServer.call(pid, {:state})
    end

    def handle_call({:state},_from,state) do
        IO.puts("server state #{inspect state}")
        {:reply, state, state}
    end

    def set_tweet(pid,tweet,user)do
        IO.puts "I am inside send tweet method  of server #{inspect pid}"
        GenServer.cast(pid,{:setTweet,tweet,user})
    end
    def handle_cast({:setTweet,stweet,user},state) do
        pid=Map.get(state,:pid)
        IO.puts "I am inside send tweet method  of server #{inspect pid}"
        tweet=Map.get(state,:tweet)
        s=[user,stweet]
        state = Map.put(state, :tweet,tweet++[s])
        IO.inspect(state)
        {:noreply, state}
    end

    def handle_call({:tweet, user, tweet, timestamp, isRetweet, origin}, _from, state) do
        if isRetweet do 
            IO.puts "#{user} tweeted: #{tweet}"
        else 
            IO.puts "#{user} retweeted #{origin}: #{tweet}"
        end
        
        tweetid = Integer.to_string(user)<>"_"<>Integer.to_string(timestamp)
        tweetinfo = process(tweet, tweetid)

        state = updateState(tweetinfo, state, :mentions)
        state = updateState(tweetinfo, state, :hashtags)

        state = Kernel.put_in(state, [:tweets, tweetid], [tweet, isRetweet])
            
        {_, state} = Kernel.get_and_update_in(state, [:usertweets, user], fn x -> 
            if x == nil do 
                {x, [tweetid]}
            else 
                {x, x ++ [tweetid]}
            end
        end) 

        follower_list = state[:subscribers][user]
        
        IO.inspect follower_list
        server = self()

        #TODO : alive dead 

        Enum.each(follower_list, fn follower ->
            spawn(fn -> 
                GenServer.call(state[:user][follower], {:subscriberTweeted, tweet, user})                
            end)
        end)

        {:reply, [], state}
    end

    def updateState(tweetinfo, state, index) do
        Enum.reduce(tweetinfo[index], state, fn i, acc ->
            i = String.slice(i, 1, String.length(i)) 

            {_, acc} = Kernel.get_and_update_in(acc, [index, i], fn x -> 
                if x == nil do 
                    {x, [tweetinfo[:tweetid]]}
                else 
                    {x, x ++ [tweetinfo[:tweetid]]}
                end
            end)

            acc
        end)
    end

    def process(tweet, tweetid) do
        words = String.split(tweet)
        
        mentions = Enum.filter(words, fn word ->
            String.at(word, 0) == "@" 
        end)

        hashtags = Enum.filter(words, fn word ->
            String.at(word, 0) == "#" 
        end)

        %{
            :tweetid => tweetid,
            :mentions => mentions,
            :hashtags => hashtags,
            :tweet => tweet
        }
    end
end
