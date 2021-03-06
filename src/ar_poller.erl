-module(ar_poller).
-export([start/2]).
-include("ar.hrl").

%%% This module spawns a process that regularly checks for updates to
%%% the current block and returns it if a new one is found.

%% The time to poll peers for a new current block.
-define(POLL_TIME, 10*1000).

%% @doc Starts poll server.
start(Node, Peers) ->
	spawn(
		fun() ->
			server(Node, Peers)
		end
	).

%% @doc Regularly poll peers for a new block.
server(Node, Peers) -> server(Node, Peers, undefined).
server(Node, Peers, LastB) ->
	receive after ?POLL_TIME -> ok end,
	case ar_node:get_current_block(Peers) of
		LastB -> server(Node, Peers, LastB);
		NewB ->
			Node ! {
				new_block,
				hd(Peers),
				NewB#block.height,
				NewB,
				ar_node:get_block(
					Peers,
					lists:nth(
						1 + ar_weave:calculate_recall_block(NewB),
						lists:reverse(NewB#block.hash_list)
					)
				)
			},
			server(Node, Peers, NewB)
	end.
