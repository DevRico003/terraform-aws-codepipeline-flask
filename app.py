
from flask import Flask, render_template

app = Flask(__name__)

# Dummy-Produktliste
products = [
    {"id": 1, "name": "Produkt 1", "price": 10.99},
    {"id": 2, "name": "Produkt 2", "price": 12.99},
    {"id": 3, "name": "Produkt 3", "price": 9.99}
]

@app.route('/')
def home():
    return render_template('index.html', products=products)

if __name__ == '__main__':
    app.run(debug=True)
