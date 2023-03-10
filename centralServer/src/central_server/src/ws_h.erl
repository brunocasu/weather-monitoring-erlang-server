-module(ws_h).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).

-import(listener_task, [start_monitoring_listener/1]).

init(Req, State) ->
	{cowboy_websocket, Req, State, #{
		idle_timeout => 6000000}}. %% 100 min timeout

websocket_init(State) ->
	io:fwrite("~p~n", ["new connection..."]),
	io:fwrite("~p~n", [self()]),
	start_monitoring_listener(self()),
	{[], State}.

websocket_handle(_Data, State) ->
	{[], State}.

websocket_info({ServerID, SensorID, Data, DataType, Time}, State) ->
	Body = build_json_reply(ServerID, SensorID, Data, DataType, Time),
	io:fwrite("~p~n", ["websocket stream..."]),
	{[{text, Body}], State};
websocket_info(_Info, State) ->
	{[], State}.

build_json_reply(ServerID, SensorID, Data, DataType, Time) ->
	ServerIDKey = <<"{\"server_id\":\"">>,
	ServerIDBin = <<ServerIDKey/binary, ServerID/binary>>,
	IDKey = <<"\",\"sensor_id\":\"">>,
	IDBin = <<IDKey/binary, SensorID/binary>>,
	DataKey = <<"\",\"data\":\"">>,
	DataBin = <<DataKey/binary, Data/binary>>,
	TypeKey = <<"\",\"data_type\":\"">>,
	TypeBin = <<TypeKey/binary, DataType/binary>>,
	TimeKey = <<"\",\"time\":\"">>,
	TimeBin = <<TimeKey/binary, Time/binary>>,
	End = <<"\"}">>,
	Body = <<ServerIDBin/binary, IDBin/binary, DataBin/binary, TypeBin/binary, TimeBin/binary, End/binary>>,
	Body.