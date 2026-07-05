# 🔥 تثبيت Firebase CLI - خطوة بخطوة

## المشكلة
`npm install -g firebase-tools` مش شغال لأن **Node.js مش installed**

---

## ✅ الحل - طريقتين

### الطريقة 1: باستخدام Homebrew (الأسهل) ⭐

#### الخطوة 1: Install Homebrew (لو مش موجود)
افتح **Terminal** واكتب:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### الخطوة 2: Install Node.js
```bash
brew install node
```

#### الخطوة 3: تأكد من التثبيت
```bash
node --version
npm --version
```

#### الخطوة 4: Install Firebase CLI
```bash
npm install -g firebase-tools
```

#### الخطوة 5: تأكد من Firebase CLI
```bash
firebase --version
```

---

### الطريقة 2: Download Node.js مباشرة

#### الخطوة 1: Download Node.js
افتح المتصفح وروح:
```
https://nodejs.org/
```

#### الخطوة 2: Download macOS Installer
- اضغط على **Download** (النسخة LTS)
- افتح الملف `.pkg` اللي حملته
- اتبع التعليمات

#### الخطوة 3: أعد فتح Terminal
```bash
# أغلق Terminal وافتحه تاني
node --version
npm --version
```

#### الخطوة 4: Install Firebase CLI
```bash
sudo npm install -g firebase-tools
```

**لو طلب password، اكتب password الـ Mac بتاعك**

---

## 🧪 بعد التثبيت - اختبر

### في Terminal:
```bash
firebase --version
```

**لو طلع رقم version = تمام ✅**

---

## 🚀 الخطوات بعد كده

### 1. Login to Firebase
```bash
firebase login
```
هيفتحلك المتصفح → سجل دخول بـ Google

### 2. Set Project
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
firebase use clinicalsystem-4da35
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

**هياخد 5-10 دقايق** ⏱

---

## 🔍 لو في مشاكل

### Problem 1: "permission denied"
**الحل:**
```bash
sudo npm install -g firebase-tools
```

### Problem 2: "npm: command not found"
**الحل:**
- Node.js مش installed صح
- اعمل restart للـ Mac
- جرب تاني

### Problem 3: "firebase: command not found"
**الحل:**
```bash
# Add to PATH
echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.zshrc
source ~/.zshrc
```

---

## 📋 Quick Commands Summary

```bash
# 1. Install Homebrew (لو مش موجود)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Node.js
brew install node

# 3. Install Firebase CLI
npm install -g firebase-tools

# 4. Login
firebase login

# 5. Set Project
cd /Users/georgesadek/Downloads/clinicalSys-main
firebase use clinicalsystem-4da35

# 6. Deploy
firebase deploy --only functions
```

---

## 🎯 بعد الـ Deploy

الإشعارات هتشتغل **تلقائياً** لـ:
- ✅ حجوزات العيادات
- ✅ عروض الصيدليات
- ✅ طلبات الأدوية
- ✅ حجوزات المعامل

---

## ⏱ كم هياخد وقت؟

- Install Homebrew: 2-5 دقايق
- Install Node.js: 1-2 دقيقة
- Install Firebase CLI: 1-2 دقيقة
- Deploy Functions: 5-10 دقايق

**المجموع: حوالي 10-20 دقيقة** ⏰

---

## 💡 نصيحة

**استخدم Homebrew** (الطريقة 1) لأنها:
- ✅ أسهل
- ✅ أسرع
- ✅ أقل مشاكل
- ✅ سهلة التحديث

---

## 📞 للمساعدة

إذا واجهت أي مشكلة:
1. تأكد إنك فاتح **Terminal** (مش أي برنامج تاني)
2. جرب **restart** للـ Mac
3. تأكد من **internet connection**
4. لو لسه مش شغال، ابعت الـ error message

---

**ابدأ بالطريقة 1 (Homebrew) دلوقتي!** 🚀
