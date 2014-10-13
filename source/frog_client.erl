-module(frog_client).
-export([send/0]).
-import(marshalling, [encode/2, decode/1]).
-import(utils, [print_peer_addr/2]).

send() ->
    {ok, Socket} = 
	gen_tcp:connect("localhost", 9878,
			[binary, {packet, 0}]),
	print_peer_addr("connected",Socket),

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
	
	ok = gen_tcp:send(Socket, list_to_binary(Request)),
	io:format("to receive~n"),
	expect_message(Socket,<<>>).

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
		io:format("peer closed~n")
    end.
	
on_message({Socket,Cmd,Body}) ->
    case Cmd of
        321 ->
		    <<ID:32/big,StrLen:32/big,Str:StrLen/binary-unit:8>> = Body,
			L = "id:" ++ integer_to_list(ID) ++ 
			" strlen:" ++ integer_to_list(StrLen) ++ 
			" str:" ++ Str,
			io:format("receive cmd:321, ~s~n",[L]),
			gen_tcp:close(Socket);
		Other -> 
		    io:format("unknown cmd:~s~n",[integer_to_list(Other)])
	end.
