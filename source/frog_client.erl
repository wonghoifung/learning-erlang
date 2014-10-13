-module(frog_client).
-compile(export_all).
-import(lists, [reverse/1]).

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

%header: | flag_2 | cmd_2 | version_1 | subversion_1 | bodylen_2 | checkcode_1 |
send() ->
    {ok, Socket} = 
	gen_tcp:connect("localhost", 9878,
			[binary, {packet, 0}]),
	print_peer_addr("connected",Socket),
	
	Str = <<"helloworld">>,%68 65 6c 6c 6f 77 6f 72 6c 64
	StrLen=length(binary_to_list(Str))+1,
	StrList=binary_to_list(<<StrLen:32>>)++binary_to_list(Str)++fill(0,1,[]),

	Int1=999,
	Short1=888,
	Short2=777,
	Int2=666,
	
	Cmd=123,
	Ver=7,
	SVer=8,
	BodyLen=4+2+4+StrLen+2+4,
	ChkCode=0,
	
	Request=[16#47]++[16#50]++binary_to_list(<<Cmd:16>>)++
							  binary_to_list(<<Ver:8>>)++
							  binary_to_list(<<SVer:8>>)++
							  binary_to_list(<<BodyLen:16>>)++
							  binary_to_list(<<ChkCode:8>>)++
							  binary_to_list(<<Int1:32>>)++
							  binary_to_list(<<Short1:16>>)++
							  StrList++
							  binary_to_list(<<Short2:16>>)++
							  binary_to_list(<<Int2:32>>),
	ok = gen_tcp:send(Socket, list_to_binary(Request)),
	io:format("to receive~n"),
	loop(Socket,<<>>).

loop(Socket,Left) ->
    receive
	{tcp, Socket, Bin} ->
		Buffer=list_to_binary(binary_to_list(Left) ++ binary_to_list(Bin)),
		case decode(Buffer) of
			{ok,Remaining} ->
				Remaining,
			    gen_tcp:close(Socket);
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
				321 ->
					<<ID:32/big,StrLen:32/big,Str:StrLen/binary-unit:8>> = Body,
					L = "id:" ++ integer_to_list(ID) ++ 
					    " strlen:" ++ integer_to_list(StrLen) ++ 
						" str:" ++ Str,
					io:format("receive cmd:321, ~s~n",[L]);
				Other ->
					io:format("unknown cmd:~s~n",[integer_to_list(Other)])
			end,
			{ok,Left};
		<<_/binary>> ->
			{not_enough_bytes}
	end.

