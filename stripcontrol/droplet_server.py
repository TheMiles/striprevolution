import sys
sys.path.append("..")

print sys.path

import gpio, bottle, json, droplets, thread

PORT = 80
HOST = "192.168.178.49"#0.194"

if __name__ == "__main__":

    gpio.setup()

    thread.start_new_thread(droplets.main, ())

    @bottle.route('/static/<filepath:path>')
    def static(filepath):
        return bottle.static_file(filepath, root='www/static')

    @bottle.route("/")
    def index():
        gpio.blink()
	data = {"title": "StripRevolution Control"}
	return bottle.template('www/index', data=data)

    @bottle.route("/engine/<filename>")
    def engine(filename):
        gpio.blink()
	data = {"title": filename}
	return bottle.template('www/engine', data=data)

    @bottle.route("/engine/edit/<filename>")
    def engine(filename):
        gpio.blink()
	data = {"title": filename}
	return bottle.template('www/edit', data=data)

    @bottle.post("/request")
    def request():
        gpio.blink()
	data = {}
	for d in bottle.request.json:
		data[d["name"]] = float(d["value"]) / 100.0
        droplets.set(data)
	bottle.response.content_type = "application/json"
	return json.dumps("success")

#    bottle.debug(True)
    bottle.run(host=HOST, port=PORT)#, reloader=True)

    gpio.cleanup()
