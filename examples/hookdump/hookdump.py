from flask import Flask, request

app = Flask(__name__)

@app.route("/hello")
def hello_world():
    return "<p>Hallo Welt!</p>"

@app.route("/dump", methods=["POST"])
def dump_payload():
    print(request.get_data(as_text=True))
    return "<p>Payload nach stdout gedumpt.</p>"
