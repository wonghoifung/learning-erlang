-module(marshalling).
-export([encode/2, decode/1]).
-import(utils, [fill/3]).

%header: | flag_2 | cmd_2 | version_1 | subversion_1 | bodylen_2 | checkcode_1 |

encode(List,{int64,Val}) -> List ++ binary_to_list(<<Val:64>>);
encode(List,{int32,Val}) -> List ++ binary_to_list(<<Val:32>>);
encode(List,{int16,Val}) -> List ++ binary_to_list(<<Val:16>>);
encode(List,{int8,Val}) -> List ++ binary_to_list(<<Val:8>>);
encode(List,{bytes,Bin}) -> 
    Bytes = Bin, % binary
	BytesLen=length(binary_to_list(Bytes)),
	BytesList=binary_to_list(<<BytesLen:32>>)++binary_to_list(Bytes),
    List ++ BytesList;
encode(List,{cstr,Bin}) -> 
	Str = Bin, % Bin is like: <<"hello">>
	StrLen=length(binary_to_list(Str))+1,
	StrList=binary_to_list(<<StrLen:32>>)++binary_to_list(Str)++fill(0,1,[]),
    List ++ StrList;
encode(List,{done,Cmd}) ->
	Ver=1,
	SVer=1,
	BodyLen=length(List),
	ChkCode=0,
    [16#47]++[16#50]++binary_to_list(<<Cmd:16>>)++
					  binary_to_list(<<Ver:8>>)++
					  binary_to_list(<<SVer:8>>)++
					  binary_to_list(<<BodyLen:16>>)++
					  binary_to_list(<<ChkCode:8>>)++
					  List.
					  
decode(Buffer) ->
	case Buffer of
		<<16#47:8,16#50:8,Cmd:16/big,_Ver:8,_SVer:8,
		BodyLen:16/big,_ChkCode:8,Body:BodyLen/binary-unit:8,
		Left/binary>> ->
			{ok,Cmd,Body,Left};
		<<_/binary>> ->
			{not_enough_bytes}
	end.
	
%decode({int64,Bin}) -> <<Int64:64,Left/binary>> = Bin, {Int64,Left};
%decode({int32,Bin}) -> <<Int32:32,Left/binary>> = Bin, {Int32,Left};
%decode({int16,Bin}) -> <<Int16:16,Left/binary>> = Bin, {Int16,Left};
%decode({int8,Bin}) -> <<Int8:8,Left/binary>> = Bin, {Int8,Left};
%decode({bytes,Bin}) ->
%    <<BytesLen:32/big,Bytes:BytesLen/binary-unit:8,Left/binary>> = Bin,
%	{Bytes,Left};
%decode({cstr,Bin}) ->
%    <<StrLen:32/big,Str:StrLen/binary-unit:8,Left/binary>> = Bin,
%	{Str,Left}.
	
