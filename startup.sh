ps aux | grep -i epmd | awk {'print $2'} | xargs kill -9
mix escript.build
./project4 server