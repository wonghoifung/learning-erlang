-module(gpsock).
-compile(export_all).
-import(lists, [reverse/1]).

print_peer_addr(L, Socket) ->
	{ok, {PeerIP, PeerPort}} = inet:peername(Socket),
	{N1,N2,N3,N4} = PeerIP, 
	L0 = L ++  " peer: "  ++ integer_to_list(N1) ++ ".",
	L1 = L0 ++ integer_to_list(N2) ++ ".",
	L2 = L1 ++ integer_to_list(N3) ++ ".",
	L3 = L2 ++ integer_to_list(N4) ++ ":",
	L4 = L3 ++ integer_to_list(PeerPort),
	io:format("~s~n",[L4]).

%%%%%% client %%%%%%
%header: | flag_2 | cmd_2 | version_1 | subversion_1 | bodylen_2 | checkcode_1 |
client() ->
    {ok, Socket} = 
	gen_tcp:connect("localhost", 2345,
			[binary, {packet, 0}]),
	print_peer_addr("connected",Socket),
	
	Cmd=1,
	BodyLen=4,
	Body=12345,
	Ver=1,
	SVer=1,
	ChkCode=0,
	Request=[16#47]++[16#50]++binary_to_list(<<Cmd:16>>)++
							  binary_to_list(<<Ver:8>>)++
							  binary_to_list(<<SVer:8>>)++
							  binary_to_list(<<BodyLen:16>>)++
							  binary_to_list(<<ChkCode:8>>)++
							  binary_to_list(<<Body:32>>),
	ok = gen_tcp:send(Socket, list_to_binary(Request)),
	io:format("to receive~n"),
    receive
	{tcp,Socket,_Bin} ->
	    gen_tcp:close(Socket)
    end.

%%%%%% server %%%%%%
start_server() ->
    {ok, Listen} = gen_tcp:listen(2345, [binary, {packet, 0},  
					 {reuseaddr, true},
					 {active, true}]),
	spawn(fun() -> par_connect(Listen) end).

par_connect(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),  
	print_peer_addr("connected",Socket),
	spawn(fun() -> par_connect(Listen) end),
	inet:setopts(Socket,[binary,{packet,0},{active,true}]),
	loop(Socket,<<>>).

loop(Socket,Left) ->
    receive
	{tcp, Socket, Bin} ->
		Buffer=list_to_binary(binary_to_list(Left) ++ binary_to_list(Bin)),
		case decode(Buffer) of
			{ok,Remaining} ->
				loop(Socket,Remaining);
			{not_enough_bytes} ->
				loop(Socket,Buffer)	
		end;
	{tcp_closed, Socket} ->
		io:format("peer closed~n")
    end.

%header: | flag_2 | cmd_2 | version_1 | subversion_1 | bodylen_2 | checkcode_1 |
decode(Buffer) ->
	case Buffer of
		<<16#47:8,16#50:8,Cmd:16/big,_Ver:8,_SVer:8,
		BodyLen:16/big,_ChkCode:8,Body:BodyLen/binary-unit:8,
		Left/binary>> ->
			case Cmd of
				1 ->
					<<ID:32/big>> = Body,
					io:format("cmd:1, id:~s~n",[integer_to_list(ID)]);
				Other ->
					io:format("unknown cmd:~s~n",[integer_to_list(Other)])
			end,
			{ok,Left};
		<<_/binary>> ->
			{not_enough_bytes}
	end.

