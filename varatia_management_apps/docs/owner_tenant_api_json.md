# Owner Tenant API JSON

Tenant residence details come from the assigned property/unit. Create uses
`propertyId`; list/update responses should return the resolved location,
building, floor, and unit names so the owner can identify where the tenant
stays.

## Entry

`POST /api/owner/tenants`

Request:

```json
{
  "fullName": "Rahim Uddin",
  "phoneNumber": "01711111111",
  "nid": "1991234567890",
  "propertyId": "UNIT-001"
}
```

Response:

```json
{
  "message": "Tenant created successfully.",
  "propertyId": "UNIT-001",
  "propertyName": "Flat A",
  "loginPhoneNumber": "01711111111",
  "temporaryPassword": "A7K9P2",
  "credentialSmsSent": true,
  "credentialSmsError": "",
  "tenant": {
    "id": "TEN-001",
    "name": "Rahim Uddin",
    "phone": "01711111111",
    "nid": "1991234567890",
    "propertyId": "UNIT-001",
    "propertyName": "Flat A",
    "location": "Dhanmondi, Dhaka",
    "buildingId": "BLD-001",
    "buildingName": "Building A",
    "floorId": "FLR-001",
    "floorLabel": "Floor 1"
  }
}
```

## List

`GET /api/owner/tenants`

Response:

```json
{
  "tenants": [
    {
      "id": "TEN-001",
      "name": "Rahim Uddin",
      "phone": "01711111111",
      "nid": "1991234567890",
      "propertyId": "UNIT-001",
      "propertyName": "Flat A",
      "location": "Dhanmondi, Dhaka",
      "buildingId": "BLD-001",
      "buildingName": "Building A",
      "floorId": "FLR-001",
      "floorLabel": "Floor 1"
    }
  ]
}
```

## Edit

`PUT /api/owner/tenants/{tenantId}`

Request:

```json
{
  "fullName": "Rahim Uddin Updated",
  "phoneNumber": "01811111111",
  "nid": "1991234567890"
}
```

Response:

```json
{
  "message": "Tenant updated successfully.",
  "propertyId": "UNIT-001",
  "propertyName": "Flat A",
  "tenant": {
    "id": "TEN-001",
    "name": "Rahim Uddin Updated",
    "phone": "01811111111",
    "nid": "1991234567890",
    "propertyId": "UNIT-001",
    "propertyName": "Flat A",
    "location": "Dhanmondi, Dhaka",
    "buildingId": "BLD-001",
    "buildingName": "Building A",
    "floorId": "FLR-001",
    "floorLabel": "Floor 1"
  }
}
```

## Delete

`DELETE /api/owner/tenants/{tenantId}`

Response:

```json
{
  "message": "Tenant deleted successfully.",
  "tenantId": "TEN-001",
  "propertyId": "UNIT-001",
  "propertyName": "Flat A",
  "location": "Dhanmondi, Dhaka",
  "buildingId": "BLD-001",
  "buildingName": "Building A",
  "floorId": "FLR-001",
  "floorLabel": "Floor 1"
}
```
