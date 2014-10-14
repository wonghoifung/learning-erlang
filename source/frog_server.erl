-module(frog_server).
-export([start/0]).
-import(marshalling, [encode/2, decode/1]).
-import(utils, [print_peer_addr/2, peer_to_list/1]).

start() ->
    {ok, Listen} = gen_tcp:listen(9878, [binary, {packet, 0},  
					 {reuseaddr, true},
					 {active, true}]),
	spawn(fun() -> par_connect(Listen) end).

par_connect(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),  
	print_peer_addr("connected",Socket),
	spawn(fun() -> par_connect(Listen) end),
	inet:setopts(Socket,[binary,{packet,0},{active,true}]),
	case expect_message(Socket,<<>>) of
		Reason ->
			io:format("process:~p stop:~p~n",[self(),Reason])
	end.

expect_message(Socket,Left) ->
    receive
	{tcp, Socket, Bin} ->
		Buffer=list_to_binary(binary_to_list(Left) ++ binary_to_list(Bin)),
		case decode(Buffer) of
			{ok,Cmd,Body,Remaining} ->
				case on_message({Socket,Cmd,Body}) of
					{ok} ->
						expect_message(Socket,Remaining);
					{error,Reason} ->
						gen_tcp:close(Socket),
						{error,Reason}	
				end;
			{not_enough_bytes} ->
				expect_message(Socket,Buffer)	
		end;
	{tcp_closed, Socket} ->
		{error,peer_closed}
    end.
	
on_message({Socket,Cmd,Body}) ->
    case Cmd of
        123 ->
		    <<Int1:32/big,Short1:16/big,
			StrLen:32/big,Str:StrLen/binary-unit:8,
			Short2:16/big,Int2:32/big>> = Body,
			io:format("process:~p peer:~p receive:[~p,~p,~p,~p,~p]~n",
				[self(),peer_to_list(Socket),Int1,Short1,list_to_atom(binary_to_list(Str)),Short2,Int2]),
			%io:format("process:~p peer:~p receive:[~p,~p,~s,~p,~p]~n",
			%	[self(),peer_to_list(Socket),Int1,Short1,binary_to_list(Str),Short2,Int2]),
			
			L1 = encode([],{int32,8888}),
			L2 = encode(L1,{cstr,<<"frog success">>}),	
			Response = encode(L2,{done,321}),
			case gen_tcp:send(Socket, list_to_binary(Response)) of
				ok -> 
					{ok};
				{error, Reason} ->
					{error,list_to_atom("cannot_send_" ++ atom_to_list(Reason))}
			end;
		Other -> 
			{error,list_to_atom("unknown_message_" ++ integer_to_list(Other))}
	end.
