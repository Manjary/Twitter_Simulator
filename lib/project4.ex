defmodule Project4 do
  @noOfUsers 1000

  def main(args \\ []) do
    input=Enum.at(to_charlist(args),0)

    if "#{input}" == "server" do
      {_,spid}= MainServer.start_link()
      IO.puts("serverProcessID #{inspect spid}")
      GenServer.cast(spid,{:noOfClients,@noOfUsers})

      _ = System.cmd("epmd", ['-daemon'])
      {:ok, _} = Node.start(String.to_atom("server@127.0.0.1"))
      :global.register_name(:head, spid)
      :timer.sleep(600000)
    end

    if "#{input}" == "client" do
      _ = System.cmd("epmd", ['-daemon'])
      {:ok, _} = Node.start(String.to_atom("client@127.0.0.1"))
      b = Node.connect(String.to_atom("server@127.0.0.1"))

      if b do
          :global.sync()
          spid = :global.whereis_name(:head)
          IO.inspect spid
          IO.puts "connected"

          {:ok, sid} = Simulator.start_link(@noOfUsers, spid)
          Simulator.startFollowersMap(sid)
          :timer.sleep 100000000
      else
        IO.puts "error"
      end

    end

 if "#{input}" == "query" do
      _ = System.cmd("epmd", ['-daemon'])
      {:ok, _} = Node.start(String.to_atom("query@127.0.0.1"))
      b = Node.connect(String.to_atom("server@127.0.0.1"))
      d = Node.connect(String.to_atom("client@127.0.0.1")) 
      if d do
         IO.puts "connected to clint"
      end
      if b do
          :global.sync()
          spid = :global.whereis_name(:head)
          IO.inspect spid
          IO.puts "connected"

          IO.puts "*********************************************************************"
          IO.puts "                           1.Mentions              "
          IO.puts "                           2.Hashtag               " 
          IO.puts "                           3.Subscriber tweet               " 
          IO.puts "*********************************************************************"
          {input,_} =Integer.parse(String.replace((IO.gets "what is ur choice 1  2 or 3 ?"),"\n",""))
          if input == 1 do
           IO.puts "mentioned"
           {mention,_} = Integer.parse(String.replace((IO.gets "whom you want to search"),"\n",""))
           Querysimulator.start_link(mention,spid,"mention")
          end
          
          if input == 2 do
             IO.puts "hashtag"
             hashtag = String.replace((IO.gets "which hashtag ... pls enter without #"),"\n","")
             Querysimulator.start_link(hashtag,spid,"hashtag")
          end


          if input == 3 do
            IO.puts  "subscriber"
            {name,_} = Integer.parse(String.replace((IO.gets "Enter your name"),"\n",""))
            IO.inspect name
            Querysimulator.start_link(name,spid,"name")

          end

           :timer.sleep(1000000)
      else
        IO.puts "error"
      end

    end
    
if "#{input}" == "live" do
      _ = System.cmd("epmd", ['-daemon'])
      {:ok, _} = Node.start(String.to_atom("clientName@127.0.0.1"))
      b = Node.connect(String.to_atom("server@127.0.0.1"))

      if b do
           {name,_} = Integer.parse(String.replace((IO.gets "Enter your id"),"\n",""))
           Livesimulator.start_link(name,spid)

           :timer.sleep(1000000)
      else
        IO.puts "error"
      end

    end



 end

end
