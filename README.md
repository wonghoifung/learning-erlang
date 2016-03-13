frog-erlang
===========

learning erlang

See how to do stress testing below:
==================================
$ cd frog-erlang/

$ erl

1> frog_client:start_kvs().

true

2> frog_client:start(10).

process:<0.37.0>,ok elasped:0seconds 

process:<0.38.0>,ok elasped:0seconds 

process:<0.39.0>,ok elasped:0seconds

...
