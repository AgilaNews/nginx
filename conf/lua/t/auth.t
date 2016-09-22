use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: sign
--- config
    location ~ /(.*)$ {
        set $req_path $1;
        access_by_lua_file "/home/zhangguanxing/log-collector/lua/auth.lua";
        content_by_lua_file "/home/zhangguanxing/log-collector/lua/content.lua";
    }

--- request
GET /req

--- more_headers
X-USER-A: zhangguanxing
X-USER-D: zhangguanxing
AUTHORIZATION: singnature

--- response_body
hehe
--- error_code: 100
