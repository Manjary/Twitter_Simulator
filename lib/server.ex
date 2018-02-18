defmodule Server do
    def init(_) do
        state = %{:followerMap=>%{},:user=>%{}}
        {:ok, state}
    end

    def handle_cast({:initialize, servers, hashtagcentres, selfdatacentre, lf}, state) do
        state = Map.put(state, :servers, servers)
        state = Map.put(state, :hashtagcentres, hashtagcentres)
        state = Map.put(state, :selfdatacentre, selfdatacentre)
        state = Map.put(state, :lf, lf)

        {:noreply, state}
    end


    def handle_cast({:tweet, user, tweet, timestamp, retweet, origin}, state) do
   
        if retweet do
            IO.puts "client #{user} retweeted #{origin} : #{tweet} with timestamp #{timestamp}"
        else
            IO.puts "client #{user} tweeted: #{tweet} with timestamp #{timestamp}"
        end

        serverId =  user / state[:lf] |> round 
        
        followers = state[:followerMap][user]
        #IO.inspect(length(followers))
        Enum.each(followers, fn follower -> 
             serverId =  follower / state[:lf] |> round
             GenServer.cast(state[:servers][serverId][:server], {:deliver_tweet, follower, user, tweet, timestamp, retweet, origin})
        end)
        tweetid = Integer.to_string(user)<>"_"<>Integer.to_string(timestamp)
          tweet_data = process( tweet, tweetid)
        GenServer.cast(state[:selfdatacentre], {:store_tweet, tweet_data[:tweet_id], user, tweet, timestamp, retweet, origin})
        
        ## update hashtag 
        Enum.each(tweet_data[:hashtags], fn hashtag ->
             hashtag = String.slice(hashtag, 1, String.length(hashtag))
             hashtag_store_idx = String.at(hashtag, 0)
             GenServer.cast(state[:hashtagcentres][hashtag_store_idx], {:link_tweet, hashtag, user, tweet, retweet, origin})         
         end)

         Enum.each(tweet_data[:mentions], fn mention -> 
             mention = String.slice(mention, 1, String.length(mention))
             mention = String.to_integer(mention)

             serverId = mention / state[:lf] |> round
             GenServer.cast(state[:servers][serverId][:datacentre], {:mentioned, mention, user, tweet, retweet, origin})    
         end)

        {:noreply ,state}    
    end
      # TODO : handle sleeping nodes
    def handle_cast({:deliver_tweet, user, source, tweet, timestamp, retweet, origin}, state) do
        user_pid =state[:user][user]
        IO.puts "client #{inspect source} tweeted #{inspect tweet} at time #{inspect timestamp}"
        GenServer.cast(user_pid, {:subscriberTweeted, source, tweet, timestamp, retweet, origin})
        GenServer.cast({:global,:querysimulator }, {:receivedtweet, source, tweet, timestamp, retweet, origin})
        {:noreply, state}
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

     def handle_cast({:setfollowers,rank,follower},state) do
        state = Kernel.put_in(state,[:followerMap,rank],follower)
       {:noreply,state} 
    end

    def handle_cast({:setusers,rank,pid},state) do
        state = Kernel.put_in(state,[:user,rank],pid)
       {:noreply,state} 
    end

     def handle_cast({:getsubscribertweet, name,spid}, state) do
        followers = state[:followerMap][name]
        Enum.each(followers, fn follower -> 
             serverId =  follower / state[:lf] |> round
             IO.inspect state[:servers][serverId][:selfdatacentre]
             GenServer.cast(state[:servers][serverId][:selfdatacentre], {:getsubscribertweetdc,follower,spid})
        end)
        {:noreply, state}
    end

end