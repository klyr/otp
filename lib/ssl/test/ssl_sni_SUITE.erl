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
          good_virtual_hosts_option,
          server_selected_hostname_default].

init_per_suite(Config0) ->
    catch crypto:stop(),
    try crypto:start() of
        ok ->
            ssl:start(),
            Result =
                (catch make_certs:all(?config(data_dir, Config0),
                                      ?config(priv_dir, Config0))),
            ct:log("Make certs  ~p~n", [Result]),

            Config1 = ssl_test_lib:make_dsa_cert(Config0),
            Config = ssl_test_lib:cert_options(Config1),
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
    {ok, _S} = (catch ssl:listen(9443, [Option])).

server_selected_hostname_default() ->
    [{doc, "Check that a server select default server (undefined) when SNI "
      "hostname is not recognized"}].
server_selected_hostname_default(Config) when is_list(Config) ->
    ClientOpts = ?config(client_opts, Config),
    ServerOpts = ?config(server_opts, Config),
    {ClientNode, ServerNode, Hostname} = ssl_test_lib:run_where(Config),
    Server = ssl_test_lib:start_server([{node, ServerNode}, {port, 0},
                                        {from, self()},
                                        {mfa, {?MODULE, sni_hostname_result, []}},
                                        {options, ServerOpts}]),

    Port = ssl_test_lib:inet_port(Server),
    Client = ssl_test_lib:start_client([{node, ClientNode}, {port, Port},
                                        {host, Hostname},
                                        {from, self()},
                                        {mfa, {ssl_test_lib, no_result, []}},
                                        {options, ClientOpts}]),
    SelectedSNI = undefined,
    ssl_test_lib:check_result(Server, SelectedSNI),

    ssl_test_lib:close(Client),
    ssl_test_lib:close(Server).

sni_hostname_result(Socket) ->
    ssl:hostname(Socket).
