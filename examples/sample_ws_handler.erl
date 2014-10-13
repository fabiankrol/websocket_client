-module(sample_ws_handler).

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
    {ok, 2, WsUri}.

terminate(_Reason, _State) ->
    ok.

handle_info(_Msg, State) ->
    {noreply, State}.


websocket_init(StartCount, _ConnState) ->
    websocket_client:cast(self(), {text, <<"init message">>}),
    {ok, StartCount}.

websocket_handle({pong, _}, _ConnState, State) ->
    {ok, State};
websocket_handle({text, Msg}, _ConnState, 5 = State) ->
    io:format("Received msg: ~p; state: ~p~n", [Msg, State]),
    {close, <<>>, "done"};
websocket_handle({text, Msg}, _ConnState, State) ->
    io:format("Received msg: ~p; state: ~p~n", [Msg, State]),
    timer:sleep(1000),
    BinInt = list_to_binary(integer_to_list(State)),
    {reply, {text, <<"hello, this is message #", BinInt/binary >>}, State + 1}.

websocket_info(start, _ConnState, State) ->
    {reply, {text, <<"erlang message received">>}, State}.

websocket_terminate(Reason, _ConnState, State) ->
    io:format("Websocket closed in state ~p wih reason ~p~n",
              [State, Reason]),
    ok.
