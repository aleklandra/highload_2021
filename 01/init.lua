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
	bypass_port = decode.proxy.bypass.port
	print('bypass_port: '..bypass_port)
	proxy_port = decode.proxy.port
	print('proxy_port: '..proxy_port)
end



local function my_handler(req) -- функция для формирвания ответа прокси-сервера
	local http_client = require('http.client').new({max_connections = 1}) -- создаем клиента
	local table = http_client:request('GET',bypass_host, bypass_port,{timeout = 1}) -- направляем запрос на указынные в конфигурационном файле хост и порт
	print(table.status)
	print(table.reason)
	if table.body == nil then
	
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


