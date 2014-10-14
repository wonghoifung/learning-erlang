-module(frog_client).
-export([send/1,start_kvs/0,start/1]).
-import(marshalling, [encode/2, decode/1]).
-import(utils, [print_peer_addr/2, peer_to_list/1]).

start_kvs() ->
	register(kvs,spawn(fun() -> dict() end)).

dict() ->  
	receive  
		{From,{store,Key,Value}} ->  
			From,
			put(Key,Value),  
			dict();  
		{From,{lookup,Key}} ->  
			From ! {lookup,get(Key)},  
		dict()  
	end.

for(N, N, F) -> [F(N)];
for(I, N, F) -> [F(I)|for(I+1, N, F)].

timestamp() ->
	{M, S, _} = os:timestamp(),
	M * 1000000 + S.

start(N) ->
	for(1, N, fun(ID) -> spawn_monitor(frog_client,send,[ID]) end),
	put(successcount,0),
	for(1, N, fun(ID) -> ID,wait() end),
	io:format("successcount:~p~n",[get(successcount)]).

wait() ->
    receive
		{'DOWN',R,process,P,Why} ->
			R,
			
			case Why of
				ok ->
					Count = get(successcount),
					put(successcount,Count+1);
				_ ->
					void
			end,

			kvs ! { self(), {lookup,P} },
			receive 
				{lookup, Start} ->
					End = timestamp(),
					Elasped = End - Start,
					io:format("process:~p,~p elasped:~pseconds ~n",[P,Why,Elasped])
			after 1000 ->
					io:format("process:~p, cannot find start time~n",[P])
			end	
    end.

send(ID) ->
	ID,
	kvs ! { self(), {store,self(),timestamp()} },
	%print_peer_addr("connected",Socket),
	case gen_tcp:connect("localhost", 9878, [binary, {packet, 0}]) of
		{ok,Socket} ->
			Int1=999,
			Short1=888,
			Short2=777,
			Int2=666,
	
			L1 = encode([],{int32,Int1}),
			L2 = encode(L1,{int16,Short1}),
			L3 = encode(L2,{cstr,<<"helloworld">>}),
			L4 = encode(L3,{int16,Short2}),
			L5 = encode(L4,{int32,Int2}),
			Request = encode(L5,{done,123}),
	
			case gen_tcp:send(Socket, list_to_binary(Request)) of
				ok ->
					case expect_message(Socket,<<>>) of
						{ok} ->
							exit(ok);
						{error,Reason} ->
							exit(list_to_atom("message_error_" ++ atom_to_list(Reason)))
					end;
				{error, Reason} ->
					gen_tcp:close(Socket),
					exit(list_to_atom("cannot_send_" ++ atom_to_list(Reason)))
			end;
		{R1,R2} ->
			R1,
			exit(list_to_atom("cannot_connect_" ++ atom_to_list(R2)))
	end.

expect_message(Socket,Left) ->
    receive
	{tcp, Socket, Bin} ->
		Buffer=list_to_binary(binary_to_list(Left) ++ binary_to_list(Bin)),
		case decode(Buffer) of
			{ok,Cmd,Body,Remaining} ->
				Remaining,
				on_message({Socket,Cmd,Body});
			{not_enough_bytes} ->
				expect_message(Socket,Buffer)	
		end;
	{tcp_closed, Socket} ->
		{error,peer_closed}
    end.
	
on_message({Socket,Cmd,Body}) ->
    case Cmd of
        321 ->
		    <<ID:32/big,StrLen:32/big,Str:StrLen/binary-unit:8>> = Body,
			%io:format("process:~p peer:~p receive:[~p,~p]~n",
			%	[self(),peer_to_list(Socket),ID,list_to_atom(binary_to_list(Str))]),
			gen_tcp:close(Socket),
			{ok};
		Other -> 
			gen_tcp:close(Socket),
			{error,list_to_atom("unknown_message_" ++ integer_to_list(Other))}
	end.
