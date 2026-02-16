# Firebase Database Schema

## Collections

### 1. users
Stores all user information (merchants, clients, admins)

```
users/{userId}
  - phoneNumber: string
  - role: string (merchant | client | admin)
  - createdAt: timestamp
  - name: string
  - shopName: string (only for merchants)
  - machineId: string (only for merchants)
```

### 2. weighing_machines
Stores weighing machine information

```
weighing_machines/{machineId}
  - merchantId: string
  - currentWeight: number
  - lastUpdated: timestamp
  - calibrationLock: boolean
  - status: string (active | inactive)
```

### 3. fish_inventory
Stores daily fish list and rates by merchant

```
fish_inventory/{inventoryId}
  - merchantId: string
  - fishName: string
  - imageUrl: string
  - ratePerKg: number
  - type: string (wholesale | retail)
  - date: string (YYYY-MM-DD)
  - createdAt: timestamp
  - updatedAt: timestamp
```

### 4. orders
Stores all orders

```
orders/{orderId}
  - merchantId: string
  - clientId: string
  - fishName: string
  - fishImageUrl: string
  - weight: number
  - ratePerKg: number
  - type: string (wholesale | retail)
  
  - fishAmount: number
  - fishGST: number (5%)
  - deliveryCharge: number (35)
  - deliveryGST: number (18% of 35)
  - totalAmount: number
  
  - paymentMethod: string (cod | online | gpay | phonepe | credit_card | debit_card | banking)
  - paymentStatus: string (pending | paid | failed)
  - orderStatus: string (active | cancelled | completed)
  - cancellationReason: string (optional)
  
  - invoiceNumber: string
  - createdAt: timestamp
  - updatedAt: timestamp
  - completedAt: timestamp (optional)
```

### 5. notifications
Stores notification history

```
notifications/{notificationId}
  - senderId: string
  - receiverId: string
  - type: string (order_update | payment | cancellation | daily_update)
  - title: string
  - message: string
  - read: boolean
  - createdAt: timestamp
```

### 6. daily_sales_summary
Stores daily sales analytics

```
daily_sales_summary/{date}_{merchantId}
  - merchantId: string
  - date: string (YYYY-MM-DD)
  - totalSalesAmount: number
  - totalFishSoldKg: number
  - totalFishGST: number
  - totalDeliveryGST: number
  - paidOrders: number
  - codOrders: number
  - cancelledOrders: number
  - createdAt: timestamp
```

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /weighing_machines/{machineId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /fish_inventory/{inventoryId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'merchant';
    }
    
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'merchant' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'client');
    }
    
    match /notifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /daily_sales_summary/{summaryId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'merchant';
    }
  }
}
```

## Firebase Storage Structure

```
/fish_images/{merchantId}/{fishId}.jpg
/invoices/{orderId}.pdf
```
