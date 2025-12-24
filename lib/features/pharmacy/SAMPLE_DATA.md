# بيانات تجريبية للصيدليات
# قم بإضافة هذه البيانات في Firebase Firestore

## Collection: pharmacies

### Document 1: pharmacy_1
```json
{
  "name": "صيدلية النور",
  "address": "شارع الجمهورية، المنصورة، الدقهلية",
  "phone": "+201234567890",
  "whatsapp": "201234567890",
  "description": "صيدلية متكاملة تقدم جميع أنواع الأدوية والمستلزمات الطبية مع فريق صيادلة محترف",
  "latitude": 31.0364,
  "longitude": 31.3785,
  "workingHours": "من 9 صباحاً إلى 11 مساءً يومياً",
  "holidays": "الجمعة من 12 ظهراً حتى 2 عصراً",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy+1",
    "https://via.placeholder.com/400x300?text=Pharmacy+1+Interior"
  ],
  "hasHomeDelivery": true,
  "deliveryFee": 15.0,
  "minimumOrderForDelivery": 50.0,
  "rating": 4.5,
  "reviewsCount": 120,
  "isOpen": true,
  "closingTime": "11:00 PM",
  "services": [
    "قياس الضغط",
    "قياس السكر",
    "استشارة صيدلي مجانية",
    "توصيل سريع"
  ]
}
```

### Document 2: pharmacy_2
```json
{
  "name": "صيدلية الشفاء",
  "address": "شارع بورسعيد، طنطا، الغربية",
  "phone": "+201098765432",
  "whatsapp": "201098765432",
  "description": "صيدلية الشفاء - خبرة أكثر من 20 عام في خدمة المرضى",
  "latitude": 30.7865,
  "longitude": 31.0004,
  "workingHours": "24 ساعة - نعمل طوال الأسبوع",
  "holidays": "لا يوجد - متاحون دائماً",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy+2"
  ],
  "hasHomeDelivery": true,
  "deliveryFee": 10.0,
  "minimumOrderForDelivery": 30.0,
  "rating": 4.8,
  "reviewsCount": 250,
  "isOpen": true,
  "closingTime": null,
  "services": [
    "متاح 24 ساعة",
    "قياس الضغط",
    "قياس السكر",
    "حقن وريدي وعضلي",
    "توصيل مجاني للطلبات فوق 100 جنيه"
  ]
}
```

### Document 3: pharmacy_3
```json
{
  "name": "صيدلية العافية",
  "address": "شارع الثورة، الزقازيق، الشرقية",
  "phone": "+201555123456",
  "whatsapp": "201555123456",
  "description": "صيدلية العافية - صحتك تهمنا",
  "latitude": 30.5852,
  "longitude": 31.5046,
  "workingHours": "من 8 صباحاً إلى 10 مساءً",
  "holidays": "الجمعة",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy+3",
    "https://via.placeholder.com/400x300?text=Pharmacy+3+Team"
  ],
  "hasHomeDelivery": false,
  "deliveryFee": null,
  "minimumOrderForDelivery": null,
  "rating": 4.2,
  "reviewsCount": 85,
  "isOpen": true,
  "closingTime": "10:00 PM",
  "services": [
    "قياس الضغط",
    "قياس الحرارة",
    "استشارة طبية",
    "منتجات عضوية"
  ]
}
```

### Document 4: pharmacy_4
```json
{
  "name": "صيدلية الحياة",
  "address": "شارع الجيش، دمياط",
  "phone": "+201777888999",
  "whatsapp": "201777888999",
  "description": "صيدلية الحياة - نوفر جميع الأدوية والمستحضرات التجميلية",
  "latitude": 31.4175,
  "longitude": 31.8144,
  "workingHours": "من 9 صباحاً إلى 12 منتصف الليل",
  "holidays": "لا يوجد",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy+4"
  ],
  "hasHomeDelivery": true,
  "deliveryFee": 20.0,
  "minimumOrderForDelivery": 100.0,
  "rating": 4.6,
  "reviewsCount": 180,
  "isOpen": false,
  "closingTime": "12:00 AM",
  "services": [
    "قياس الضغط",
    "قياس السكر",
    "قياس الوزن",
    "منتجات تجميل أصلية",
    "توصيل للمنازل"
  ]
}
```

### Document 5: pharmacy_5
```json
{
  "name": "صيدلية السلام",
  "address": "شارع النيل، بنها، القليوبية",
  "phone": "+201666555444",
  "whatsapp": "201666555444",
  "description": "صيدلية السلام - رعاية صحية متكاملة",
  "latitude": 30.4596,
  "longitude": 31.1844,
  "workingHours": "من 10 صباحاً إلى 11 مساءً",
  "holidays": "الجمعة صباحاً",
  "images": [
    "https://via.placeholder.com/400x300?text=Pharmacy+5",
    "https://via.placeholder.com/400x300?text=Pharmacy+5+Products"
  ],
  "hasHomeDelivery": true,
  "deliveryFee": 12.0,
  "minimumOrderForDelivery": 40.0,
  "rating": 4.4,
  "reviewsCount": 95,
  "isOpen": true,
  "closingTime": "11:00 PM",
  "services": [
    "قياس الضغط مجاناً",
    "قياس السكر",
    "استشارة صيدلانية",
    "توصيل سريع خلال ساعة"
  ]
}
```

## Collection: pharmacy_offers

### Document 1: offer_1
```json
{
  "pharmacyId": "pharmacy_1",
  "pharmacyName": "صيدلية النور",
  "title": "خصم 20% على جميع الفيتامينات",
  "description": "عرض خاص لمدة أسبوعين على جميع أنواع الفيتامينات والمكملات الغذائية",
  "imageUrl": "https://via.placeholder.com/300x200?text=Vitamins+20%+Off",
  "discountPercentage": 20.0,
  "startDate": "2025-01-01T00:00:00.000Z",
  "endDate": "2025-01-15T23:59:59.000Z",
  "isActive": true
}
```

### Document 2: offer_2
```json
{
  "pharmacyId": "pharmacy_2",
  "pharmacyName": "صيدلية الشفاء",
  "title": "توصيل مجاني لجميع الطلبات",
  "description": "احصل على توصيل مجاني تماماً لأي طلب بدون حد أدنى",
  "imageUrl": "https://via.placeholder.com/300x200?text=Free+Delivery",
  "discountPercentage": null,
  "startDate": "2025-01-05T00:00:00.000Z",
  "endDate": "2025-01-20T23:59:59.000Z",
  "isActive": true
}
```

### Document 3: offer_3
```json
{
  "pharmacyId": "pharmacy_4",
  "pharmacyName": "صيدلية الحياة",
  "title": "خصم 30% على مستحضرات التجميل",
  "description": "تخفيضات كبيرة على جميع منتجات العناية بالبشرة والشعر",
  "imageUrl": "https://via.placeholder.com/300x200?text=Beauty+30%+Off",
  "discountPercentage": 30.0,
  "startDate": "2025-01-01T00:00:00.000Z",
  "endDate": "2025-01-31T23:59:59.000Z",
  "isActive": true
}
```

### Document 4: offer_4
```json
{
  "pharmacyId": "pharmacy_5",
  "pharmacyName": "صيدلية السلام",
  "title": "فحص ضغط وسكر مجاني",
  "description": "احصل على فحص مجاني للضغط والسكر مع أي شراء",
  "imageUrl": "https://via.placeholder.com/300x200?text=Free+Checkup",
  "discountPercentage": null,
  "startDate": "2025-01-07T00:00:00.000Z",
  "endDate": "2025-01-21T23:59:59.000Z",
  "isActive": true
}
```

### Document 5: offer_5
```json
{
  "pharmacyId": "pharmacy_1",
  "pharmacyName": "صيدلية النور",
  "title": "خصم 15% على أدوية الأطفال",
  "description": "عرض خاص على جميع أدوية ومستلزمات الأطفال",
  "imageUrl": "https://via.placeholder.com/300x200?text=Kids+15%+Off",
  "discountPercentage": 15.0,
  "startDate": "2025-01-10T00:00:00.000Z",
  "endDate": "2025-01-25T23:59:59.000Z",
  "isActive": true
}
```

## خطوات إضافة البيانات في Firebase:

1. افتح Firebase Console
2. اختر مشروعك
3. اذهب إلى Firestore Database
4. أنشئ Collection جديدة باسم `pharmacies`
5. أضف Document لكل صيدلية باستخدام البيانات أعلاه
6. أنشئ Collection جديدة باسم `pharmacy_offers`
7. أضف Document لكل عرض باستخدام البيانات أعلاه

## ملاحظات:
- يمكنك تغيير الإحداثيات (latitude, longitude) لتتناسب مع موقعك
- يمكنك استبدال روابط الصور بصور حقيقية من Firebase Storage
- تأكد من أن pharmacyId في العروض يطابق ID الصيدلية الفعلي
- التواريخ يجب أن تكون في المستقبل لعرض العروض
