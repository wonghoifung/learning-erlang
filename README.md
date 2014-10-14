frog-erlang
===========

A network framework based on Erlang

The frog_server(erlang) does the same thing with the example server in frog(c++) repos, but acts slower.

Since erlang process is light, frog_client(erlang) can be a good help to do stress testing.

See how to do stree testing below:
==================================
$ cd frog-erlang/

$ erl

1> frog_client:start_kvs().

true

2> frog_client:start(10).

process:<0.43.0>,cannot_connect_econnrefused elasped:0seconds 

process:<0.42.0>,cannot_connect_econnrefused elasped:0seconds 

process:<0.41.0>,cannot_connect_econnrefused elasped:0seconds 

...
