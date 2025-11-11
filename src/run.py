from flask import Flask
from flask_cors import CORS
from controller.contacts import contacts_bp


app = Flask(__name__)
CORS(app)
app.register_blueprint(contacts_bp)

@app.route('/')
def home():
    return "📞 Contact Backend is Running!"

if __name__ == '__main__':
    app.run(debug=True)
