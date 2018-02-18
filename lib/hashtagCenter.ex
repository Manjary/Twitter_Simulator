defmodule HashtagCentre do
    def init(servers) do
        state = %{  :servers => servers,:data => %{}}
        {:ok, state}
    end

  def handle_cast({:link_tweet, hashtag, user, tweet, retweet, origin}, state) do
        record = %{
            :user => user,
            :tweet => tweet,
            :retweet => retweet, 
            :origin => origin
        }

        {_, state} = Kernel.get_and_update_in(state, [:data, hashtag], fn x ->
            if x == nil do
                {x, [record]}
            else 
                {x, x ++ [record]}
            end 
        end)
        {:noreply, state}
    end

    def handle_cast({:gethashtag, hashtag,spid}, state) do
       
        IO.puts "I am in gethashtag"
        IO.puts("hashtag #{inspect state[:data][hashtag]}")
        GenServer.cast({:global,:querysimulator},{:receivedhashtag,state[:data][hashtag]})
        
        {:noreply, state}
    end
end    