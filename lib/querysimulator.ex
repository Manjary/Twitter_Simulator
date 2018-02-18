defmodule Querysimulator do
    def start_link(inputval, spid,input) do
        GenServer.start_link(__MODULE__, %{:inputval=>inputval, :server=>spid,:input =>input},name: {:global, :querysimulator} )
    end

    def init(state) do  
         if state[:input] == "mention" do 
         output = GenServer.call(state[:server],{:queryMention,state[:inputval]})
         end

         if state[:input] == "hashtag" do 
         output = GenServer.call(state[:server],{:queryHashtag,state[:inputval]})
         end

        if state[:input] == "name" do 
         #output = GenServer.call(state[:server],{:getsubscribertweet,state[:inputval]})
         end
         
        {:ok, state}
    end

    def handle_call({:getMentioned,mention,spid},_from,state) do

         output = GenServer.call(spid,{:queryMention,mention})
    
         {:reply,output,state}
    end 

     def handle_cast({:receivedmentioned,mention},state) do
         
         IO.inspect(mention)

         {:noreply,state}
    end

    def handle_cast({:receivedhashtag,hashtag},state) do
         
         IO.inspect(hashtag)

         {:noreply,state}
    end  

     def handle_cast({:receivedtweet,source, tweet, timestamp, retweet, origin},state) do
         if state[:inputval] == source && state[:input] == "name" do
           IO.puts "client #{inspect source} has tweeted: #{inspect tweet} at #{inspect timestamp}"
         end
         {:noreply,state}
    end  
end