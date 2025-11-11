from flask import Blueprint, request, jsonify
from flask_cors import CORS
import models


contacts_bp = Blueprint('contacts', __name__)
CORS(contacts_bp)

@contacts_bp.route('/contacts', methods=['GET'])
def get_contacts():
    data = models.get_all_contacts()
    result = [{'id': row[0], 'name': row[1], 'phone': row[2], 'email': row[3], 'note': row[4]} for row in data]
    return jsonify(result)

@contacts_bp.route('/contacts', methods=['POST'])
def add_contact():
    data = request.get_json()
    models.add_contact(data['name'], data['phone'], data.get('email', ''), data.get('note', ''))
    return jsonify({'message': 'Contact added successfully'})

@contacts_bp.route('/contacts/<int:contact_id>', methods=['PUT'])
def update_contact(contact_id):
    data = request.get_json()
    models.update_contact(contact_id, data['name'], data['phone'], data.get('email', ''), data.get('note', ''))
    return jsonify({'message': 'Contact updated successfully'})

@contacts_bp.route('/contacts/<int:contact_id>', methods=['DELETE'])
def delete_contact(contact_id):
    models.delete_contact(contact_id)
    return jsonify({'message': 'Contact deleted successfully'})
