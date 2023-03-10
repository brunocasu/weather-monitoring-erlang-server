%%%-------------------------------------------------------------------
%%% @author brunocasu
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Feb 2023 04:52
%%%-------------------------------------------------------------------
-module(msg_formatting).
-author("brunocasu").

%% API - Provides a static HTML page with information of 2 sensors and the Event Table
-export([build_html_data_table/0, build_event_record/5]).

-import(average_calc_task, [return_avg/1]).
-import(data_log_task, [log_access/4]).
-import(event_handler_task, [event_handler/2]).

build_html_data_table() ->
  BodyTitle = <<"<html>
<head>
	<meta charset=\"utf-8\">
	<title>MONITORING SERVER XXXX</title>
		<style>
	h1 {text-align: center;}
	h2 {text-align: center;}
	</style>
</head>
<body>">>,
  BodyEnd = <<"
</body>
</html>">>,
  Header =
    <<"<h1>REGIONAL MONITORING SERVER - ID: XXXXX</h1>
				<h2>REGION TEMPERATURE (AVERAGE):
		">>,
  AvgFloat = return_avg(read),
  AvgList = float_to_list(AvgFloat, [{decimals, 2}]),
  io:fwrite("~p~n", ["Average:"]),
  io:fwrite("~p~n", [AvgList]),
  AvgBin = float_to_binary(AvgFloat, [{decimals, 2}]),
  Unit = <<"<span>&#176;</span>C</h2>">>,
  HeaderWithAvg = <<Header/binary, AvgBin/binary, Unit/binary>>,
  ConnectedNodes = nodes(), %% list of atoms
  NodesBin = serialize_nodes(ConnectedNodes),
  NodesHeader = <<"<h2> CONNECTED NODES: ">>,
  NodesHeaderEnd = <<"</h2>">>,
  CompleteHeader = <<HeaderWithAvg/binary, NodesHeader/binary, NodesBin/binary, NodesHeaderEnd/binary>>,
  TableHeader = <<"<h3>&nbsp;&nbsp
  SENSOR AAA	DATA LOG
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;
	SENSOR BBB DATA LOG
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	WARNINGS/EVENTS</h3>">>,
  {DataLog1, TimeLog1, DataLog2, TimeLog2} = log_access(read, [], [], []),
  EventLog = event_handler(read, []),
  Table = build_data_table(reverse(DataLog1), reverse(TimeLog1), reverse(DataLog2), reverse(TimeLog2), reverse(EventLog)),
  Body = <<BodyTitle/binary, CompleteHeader/binary, TableHeader/binary, Table/binary, BodyEnd/binary>>,
  Body.

build_data_table([D1H | D1T], [T1H | T1T], [D2H | D2T], [T2H | T2T], [EH | ET]) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Data1Bin = integer_to_binary(D1H),
  Time1Bin = list_to_binary(T1H),
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<Time1Bin/binary, Space/binary, Data1Bin/binary>>,
  Data2Bin = integer_to_binary(D2H),
  Time2Bin = list_to_binary(T2H),
  Combined2 = <<Time2Bin/binary, Space/binary, Data2Bin/binary>>,
  EventBin = list_to_binary(EH),
  Line = <<Front/binary, Combined1/binary, Unit/binary, Combined2/binary, Unit/binary, EventBin/binary>>,
  build_data_table(D1T, T1T, D2T, T2T, ET, Line).

build_data_table([D1H | D1T], [T1H | T1T], [D2H | D2T], [T2H | T2T], [EH | ET], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  End = <<"</p>">>,
  Data1Bin = integer_to_binary(D1H),
  Time1Bin = list_to_binary(T1H),
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<Time1Bin/binary, Space/binary, Data1Bin/binary>>,
  Data2Bin = integer_to_binary(D2H),
  Time2Bin = list_to_binary(T2H),
  Combined2 = <<Time2Bin/binary, Space/binary, Data2Bin/binary>>,
  EventBin = list_to_binary(EH),
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Unit/binary, Combined2/binary, Unit/binary, EventBin/binary, End/binary>>,
  build_data_table(D1T, T1T, D2T, T2T, ET, NewTable);

build_data_table([D1H | D1T], [T1H | T1T], [D2H | D2T], [T2H | T2T], [], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  End = <<"<span>&#176;</span>C</p>">>,
  Data1Bin = integer_to_binary(D1H),
  Time1Bin = list_to_binary(T1H),
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<Time1Bin/binary, Space/binary, Data1Bin/binary>>,
  Data2Bin = integer_to_binary(D2H),
  Time2Bin = list_to_binary(T2H),
  Combined2 = <<Time2Bin/binary, Space/binary, Data2Bin/binary>>,
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Unit/binary, Combined2/binary, End/binary>>,
  build_data_table(D1T, T1T, D2T, T2T, [], NewTable);

build_data_table([], [], [D2H | D2T], [T2H | T2T], [EH | ET], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Mid = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C">>,
  End = <<"</p>">>,
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Data2Bin = integer_to_binary(D2H),
  Time2Bin = list_to_binary(T2H),
  Combined2 = <<Time2Bin/binary, Space/binary, Data2Bin/binary>>,
  EventBin = list_to_binary(EH),
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Mid/binary, Combined2/binary, Unit/binary,
    Mid/binary, EventBin/binary, End/binary>>,
  build_data_table([], [], D2T, T2T, ET, NewTable);

build_data_table([], [], [D2H | D2T], [T2H | T2T], [], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Mid = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C</p>">>,
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Data2Bin = integer_to_binary(D2H),
  Time2Bin = list_to_binary(T2H),
  Combined2 = <<Time2Bin/binary, Space/binary, Data2Bin/binary>>,
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Mid/binary, Combined2/binary, Unit/binary>>,
  build_data_table([], [], D2T, T2T, [], NewTable);

build_data_table([D1H | D1T], [T1H | T1T], [], [], [EH | ET], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C">>,
	Mid = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  End = <<"</p>">>,
  Data1Bin = integer_to_binary(D1H),
  Time1Bin = list_to_binary(T1H),
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<Time1Bin/binary, Space/binary, Data1Bin/binary>>,
  Combined2 = <<"
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;">>,
  EventBin = list_to_binary(EH),
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Unit/binary, Mid/binary, Combined2/binary,
    Mid/binary, EventBin/binary, End/binary>>,
  build_data_table(D1T, T1T, [], [], ET, NewTable);

build_data_table([D1H | D1T], [T1H | T1T], [], [], [], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Unit = <<"<span>&#176;</span>C</p>">>,
  Data1Bin = integer_to_binary(D1H),
  Time1Bin = list_to_binary(T1H),
  Space = <<"&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Combined1 = <<Time1Bin/binary, Space/binary, Data1Bin/binary>>,
  NewTable = <<TableBin/binary, Front/binary, Combined1/binary, Unit/binary>>,
  build_data_table(D1T, T1T, [], [], [], NewTable);

build_data_table([], [], [], [], [EH | ET], TableBin) ->
  Front = <<"<p>&nbsp;&nbsp;&nbsp;&nbsp;">>,
  Space = <<"
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  ">>,
  EventBin = list_to_binary(EH),
  End = <<"</p>">>,
  NewTable = <<TableBin/binary, Front/binary, Space/binary, EventBin/binary, End/binary>>,
  build_data_table([], [], [], [], ET, NewTable);

build_data_table([], [], [], [], [], TableBin) ->
  TableBin.

build_event_record(upts, TimeBin, AvgBin, SensorIDBin, DataBin) ->
  WarningHeader = <<"XXXX Warning! UPPER_TS Crossed at: ">>,
  Space = <<" / Avg: ">>,
  Unit = <<" C - Received From Sensor: ">>,
  Reading = <<" - Reading: ">>,
  End = <<" C">>,
  EventRecordBin = <<WarningHeader/binary, TimeBin/binary, Space/binary,
    AvgBin/binary, Unit/binary, SensorIDBin/binary, Reading/binary, DataBin/binary, End/binary>>,
  binary_to_list(EventRecordBin);

build_event_record(lwts, TimeBin, AvgBin, SensorIDBin, DataBin) ->
  WarningHeader = <<"XXXX Warning! LOWER_TS Crossed at: ">>,
  Space = <<" / Avg: ">>,
  Unit = <<" C - Received From Sensor: ">>,
  Reading = <<" - Reading: ">>,
  End = <<" C">>,
  EventRecordBin = <<WarningHeader/binary, TimeBin/binary, Space/binary,
    AvgBin/binary, Unit/binary, SensorIDBin/binary, Reading/binary, DataBin/binary, End/binary>>,
  binary_to_list(EventRecordBin).

reverse([]) -> [];
reverse([H | T]) -> reverse(T) ++ [H].

serialize_nodes([H | T]) ->
  NodesBin = atom_to_binary(H, utf8),
  serialize_nodes(T, NodesBin);

serialize_nodes([]) ->
  <<"">>.

serialize_nodes([H | T], NodesBin) ->
  Node = atom_to_binary(H, utf8),
  Space = <<" / ">>,
  NewNodesBin = <<NodesBin/binary, Space/binary, Node/binary>>,
  serialize_nodes(T, NewNodesBin);

serialize_nodes([], NodesBin) ->
  NodesBin.
