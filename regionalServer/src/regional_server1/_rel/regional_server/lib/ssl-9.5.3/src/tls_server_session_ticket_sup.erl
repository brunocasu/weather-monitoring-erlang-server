%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2014-2016. All Rights Reserved.
%% 
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%% 
%% %CopyrightEnd%
%%

%%
%%----------------------------------------------------------------------
%% Purpose: Supervisor for a listen options tracker
%%----------------------------------------------------------------------
-module(tls_server_session_ticket_sup).

-behaviour(supervisor).

%% API
-export([start_link/0, start_link_dist/0]).
-export([start_child/1, start_child_dist/1]).

%% Supervisor callback
-export([init/1]).

%%%=========================================================================
%%%  API
%%%=========================================================================
start_link() ->
    supervisor:start_link({local, tracker_name(normal)}, ?MODULE, []).

start_link_dist() ->
    supervisor:start_link({local, tracker_name(dist)}, ?MODULE, []).

start_child(Args) ->
    supervisor:start_child(tracker_name(normal), Args).

start_child_dist(Args) ->
    supervisor:start_child(tracker_name(dist), Args).
  
%%%=========================================================================
%%%  Supervisor callback
%%%=========================================================================
init(_O) ->
    RestartStrategy = simple_one_for_one,
    MaxR = 0,
    MaxT = 3600,
   
    Name = undefined, % As simple_one_for_one is used.
    StartFunc = {tls_server_session_ticket, start_link, []},
    Restart = temporary, % E.g. should not be restarted
    Shutdown = 4000,
    Modules = [tls_server_session_ticket],
    Type = worker,
    
    ChildSpec = {Name, StartFunc, Restart, Shutdown, Type, Modules},
    {ok, {{RestartStrategy, MaxR, MaxT}, [ChildSpec]}}.

tracker_name(normal) ->
    ?MODULE;
tracker_name(dist) ->
    list_to_atom(atom_to_list(?MODULE) ++ "dist").
