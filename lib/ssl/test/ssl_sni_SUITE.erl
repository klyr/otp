%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2008-2013. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

%%
-module(ssl_sni_SUITE).

-compile(export_all).
-include_lib("common_test/include/ct.hrl").

%%--------------------------------------------------------------------
%% Common Test interface functions -----------------------------------
%%--------------------------------------------------------------------
suite() -> [{ct_hooks,[ts_install_cth]}].

all() -> [bad_virtual_hosts,
          bad_virtual_hosts_hostname,
          bad_virtual_hosts_option,
          good_virtual_hosts_option].

init_per_suite(Config) ->
    catch crypto:stop(),
    try crypto:start() of
        ok ->
            ssl:start(),
            Config
    catch _:_ ->
            {skip, "Crypto did not start"}
    end.

end_per_suite(_Config) ->
    ssl:stop(),
    application:stop(crypto).

bad_virtual_hosts(_Config) ->
    Option = {virtual_hosts, invalid},
     {error, {options, {virtual_hosts, invalid}}} = (catch ssl:listen(9443, [Option])).

bad_virtual_hosts_hostname(_Config) ->
    Option = {virtual_hosts, {invalid, [invalid]}},
    {error, {options, {virtual_hosts, {invalid, [invalid]}}}} = (catch ssl:listen(9443, [Option])).

bad_virtual_hosts_option(_Config) ->
    Option = {virtual_hosts, [{"host1", [invalid]}]},
    {error, {options, {not_a_valid_virtual_hosts_option_for_hostname, {"host1", invalid}}}} = (catch ssl:listen(9443, [Option])).

good_virtual_hosts_option(_Config) ->
    Option = {virtual_hosts, [{"host1", [{verify, verify_none}]}]},
    {ok, S} = (catch ssl:listen(9443, [Option])).
