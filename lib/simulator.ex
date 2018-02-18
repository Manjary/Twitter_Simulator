defmodule Simulator do
    def start_link(noOfUsers, spid) do
        GenServer.start_link(__MODULE__, %{:noOfUsers => noOfUsers, :server => spid,:followers=>%{}},name: {:global, :simulator} )
    end

    def init(initial_state) do    
        GenServer.cast(initial_state[:server], {:setNumUsers, initial_state[:noOfUsers]})
        IO.puts "initiazing the client and registering them on server"
        clients = Enum.reduce(1..initial_state[:noOfUsers], %{}, fn(s, acc) ->
            {_,cid} = Client.start_link(initial_state[:server], s)
            GenServer.cast(initial_state[:server], {:setUser,s,cid})
            IO.puts("Registering client #{inspect s} at server")
            acc = Map.put(acc, s, cid)
        end)
        
        initial_state = Map.put(initial_state, :clients, clients)
       
        {:ok, initial_state}
    end

    def startFollowersMap(pid) do
        GenServer.cast(pid, {:startFollowersMap})
    end

    def handle_cast({:startFollowersMap}, state) do
        followers = Enum.reduce(1..state[:noOfUsers], [], fn x, acc ->
            acc = acc ++ [state[:noOfUsers] / x |> round]
        end)

        Enum.each(1..state[:noOfUsers], fn rank -> 
            GenServer.cast(state[:clients][rank], {:startFollowers, Enum.at(followers, rank-1), state[:noOfUsers]})
        end)
        
        {:noreply, state}
    end

    def handle_cast({:startTweeting}, state) do
        :timer.sleep(1000)
        IO.puts "start tweeting"

        Enum.each(1..state[:noOfUsers], fn rank -> 
            send(state[:clients][rank], {:startTweeting})
        end)

        {:noreply, state}
    end
    
    def handle_cast({:setfollowers,follower},state) do
        state = Kernel.put_in(state, [:followers], follower)
        {:noreply,state}
    end

    def handle_call({:getfollowers},_from,state) do

        {:reply,state[:followers],state}
    end


end