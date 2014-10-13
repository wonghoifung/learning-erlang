-module(utils).
-export([fill/3,print_peer_addr/2]).

fill(_C,0,L) ->
	L;
fill(C,N,L) ->
	N1=N-1,
	L1=[C|L],
	fill(C,N1,L1).

print_peer_addr(L, Socket) ->
	{ok, {PeerIP, PeerPort}} = inet:peername(Socket),
	{N1,N2,N3,N4} = PeerIP, 
	L0 = L ++  " peer: "  ++ integer_to_list(N1) ++ ".",
	L1 = L0 ++ integer_to_list(N2) ++ ".",
	L2 = L1 ++ integer_to_list(N3) ++ ".",
	L3 = L2 ++ integer_to_list(N4) ++ ":",
	L4 = L3 ++ integer_to_list(PeerPort),
	io:format("~s~n",[L4]).
	