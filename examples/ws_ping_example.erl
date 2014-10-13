-module(ws_ping_example).

-behaviour(websocket_client_handler).

-export([
         start_link/0,
         init/2,
         terminate/2,
         handle_info/2,
         websocket_init/2,
         websocket_handle/3,
         websocket_info/3,
         websocket_terminate/3
        ]).

start_link() ->
    crypto:start(),
    ssl:start(),
    websocket_client:start_link("wss://echo.websocket.org", ?MODULE, []).

init([], WsUri) ->
    WsInitArgs = [
        {start_state, 2},
        {ping_interval, 1000}
    ],
    {ok, WsInitArgs, WsUri}.

terminate(_Reason, _WsUri) ->
    ok.

handle_info(_Msg, WsUri) ->
    {noreply, WsUri}.


websocket_init(Args, _ConnState) ->
    websocket_client:cast(self(), {text, <<"message 1">>}),
    %% Execute a ping every 1000 milliseconds
    {ok,
        proplists:get_value(start_state, Args),
        proplists:get_value(ping_interval, Args)
    }.

websocket_handle({pong, _Msg}, _ConnState, State) ->
    io:format("Received pong ~n"),

    %% This is how to access info about the connection/request
    Proto = websocket_req:protocol(_ConnState),
    io:format("On protocol: ~p~n", [Proto]),

    {ok, State};
websocket_handle({text, Msg}, _ConnState, 5) ->
    io:format("Received msg ~p~n", [Msg]),
    {close, <<>>, 10};
websocket_handle({text, Msg}, _ConnState, State) ->
    io:format("Received msg ~p~n", [Msg]),
    timer:sleep(1000),
    BinInt = list_to_binary(integer_to_list(State)),
    Reply = {text, <<"hello, this is message #", BinInt/binary >>},
    io:format("Replying: ~p~n", [Reply]),
    {reply, Reply, State + 1}.

websocket_info(start, _ConnState, State) ->
    {reply, {text, <<"erlang message received">>}, State}.

websocket_terminate(Reason, _ConnState, State) ->
    io:format("Websocket closed in state ~p wih reason ~p~n",
              [State, Reason]),
    ok.
