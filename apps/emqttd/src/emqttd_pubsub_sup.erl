%%%-----------------------------------------------------------------------------
%%% Copyright (c) 2012-2015 eMQTT.IO, All Rights Reserved.
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------
%%% @doc
%%% emqttd pubsub supervisor.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(emqttd_pubsub_sup).

-author("Feng Lee <feng@emqtt.io>").

-include("emqttd.hrl").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Opts = emqttd_broker:env(pubsub),
    Schedulers = erlang:system_info(schedulers),
    PoolSize = proplists:get_value(pool_size, Opts, Schedulers),
    gproc_pool:new(pubsub, hash, [{size, PoolSize}]),
    Children = lists:map(
                 fun(I) ->
                    Name = {emqttd_pubsub, I},
                    gproc_pool:add_worker(pubsub, Name, I),
                    {Name, {emqttd_pubsub, start_link, [I, Opts]},
                        permanent, 5000, worker, [emqttd_pubsub]}
                 end, lists:seq(1, PoolSize)),
    {ok, {{one_for_all, 10, 100}, Children}}.

