fio = require('fio')
local file = fio.path.lexists('config.yml') --проверяем, что есть конфигурационный файл

if file == false then 
	print('No config-fle in such dirrectory')
else 
	local fh = fio.open('config.yml',{'O_RDONLY'}) --открывает конфигурационный файл
	local config = fh:read() -- читаем конфигурационный файд
	print('File was opened ')
	fh: close() -- закрываем конфигурационный файл
	local yaml = require('yaml')
	local decode = yaml.decode(config) -- декодируем yml в lua-таблицу
	local encode = yaml.encode(decode)
	print(encode) -- проверили, что верное считали конфигурационный файл
	bypass_host = decode.proxy.bypass.host
	print('bypass_host: '..bypass_host)
	if decode.proxy.bypass.port == nil then
		bypass_port = ''
	else	
		bypass_port = decode.proxy.bypass.port
	end
	print('bypass_port: '..bypass_port)
	proxy_port = decode.proxy.port
	print('proxy_port: '..proxy_port)
end

local function hello() -- функция ответа для локального сервера
	return {
			status = 200,
			body = 'hello!'
	}
end

if bypass_host == 'localhost' then -- в случае,если проверяем работу proxy-сервера на локальном сервере
	local server_local = require('http.server').new('localhost', bypass_port) 
	local router_local = require('http.router').new()
	router_local:route({ method = 'GET',path = '/'}, hello)
	server_local:set_router(router_local)
server_local:start()

end


local function my_handler(req) -- функция для формирвания ответа прокси-сервера
	local http_client = require('http.client').new({max_connections = 1}) -- создаем клиента
	local table = http_client:request('GET','http://'..bypass_host..':'..bypass_port,'',{timeout = 1}) -- направляем запрос на указынные в конфигурационном файле хост и порт
	print(table.status) --печатаем статус для удобства проверки
	print(table.reason)
	if table.body == nil then -- у меня в ответе в консоли выводится только body, поэтому, если body отсутсвует, будем выводить статус и описание статуса
	
		table.body = 'reason: '..table.reason .. '\nstatus: '..table.status..'\n' 
	end
	return {
			status = table.status,
			reason = table.reason,
			body = table.body,
			headers = table.headers,
			proto = table.proto
		}
	 
end
	
local server = require('http.server').new('localhost', proxy_port) --создаем proxy-сервер
local router = require('http.router').new() -- задаем роутер
router:route({ method = 'GET',path = '/'}, my_handler) -- конфигурируем роутер
server:set_router(router)
server:start()



