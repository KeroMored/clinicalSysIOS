# 🔓 Enable Anonymous Authentication

## خطوة إضافية مطلوبة:

لحل مشكلة Apple Sign-In، جربنا طريقة بديلة تحتاج Anonymous Authentication.

### الخطوات:

1. روح: https://console.firebase.google.com/project/clinicalsystem-4da35/authentication/providers
2. ابحث عن **Anonymous** في قائمة Sign-in methods
3. اضغط عليه
4. اضغط **Enable**
5. Save

---

بعد كده جرب Apple Sign-In تاني - المفروض يشتغل دلوقتي!

الطريقة الجديدة:
1. تسجيل دخول مجهول سريع
2. ربط حساب Apple بالحساب المجهول
3. تحويله لحساب Apple كامل

هذا workaround معروف لمشاكل OAuth في Firebase.
