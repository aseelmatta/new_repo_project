# models.py

from typing import List, Dict, Any

class Order:
    def __init__(
        self,
        customer: str,
        items: List[str],
        status: str = 'pending',
        carrier_id: str = None,
        business_id: str = None,
        doc_id: str = None
    ):
        self.id = doc_id
        self.customer = customer
        self.items = items
        self.status = status
        self.carrier_id = carrier_id
        self.business_id = business_id

    @classmethod
    def from_dict(cls, data: Dict[str, Any], doc_id: str):
        return cls(
            customer = data.get('customer'),
            items = data.get('items', []),
            status = data.get('status', 'pending'),
            carrier_id = data.get('carrier_id'),
            business_id = data.get('business_id'),
            doc_id = doc_id
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            'customer': self.customer,
            'items': self.items,
            'status': self.status,
            'carrier_id': self.carrier_id,
            'business_id': self.business_id
        }


class Carrier:
    def __init__(
        self,
        name: str,
        phone: str,
        available: bool = True,
        doc_id: str = None
    ):
        self.id = doc_id
        self.name = name
        self.phone = phone
        self.available = available

    @classmethod
    def from_dict(cls, data: Dict[str, Any], doc_id: str):
        return cls(
            name = data.get('name'),
            phone = data.get('phone'),
            available = data.get('available', True),
            doc_id = doc_id
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'phone': self.phone,
            'available': self.available
        }


class Business:
    def __init__(
        self,
        name: str,
        address: str,
        phone: str,
        doc_id: str = None
    ):
        self.id = doc_id
        self.name = name
        self.address = address
        self.phone = phone

    @classmethod
    def from_dict(cls, data: Dict[str, Any], doc_id: str):
        return cls(
            name = data.get('name'),
            address = data.get('address'),
            phone = data.get('phone'),
            doc_id = doc_id
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'address': self.address,
            'phone': self.phone
        }
