# 📱 دليل استخدام Responsive System

## نظرة عامة

تم تطبيق نظام شامل لجعل التطبيق متجاوب على جميع أحجام الشاشات:

- 📱 **Mobile**: < 600px
- 📱 **Tablet**: 600px - 900px  
- 💻 **Desktop**: 900px - 1200px
- 🖥️ **Large Desktop**: > 1200px

---

## 🚀 طريقة الاستخدام

### 1. الطريقة السريعة - Extension Methods

```dart
import 'package:clinicalsystem/core/utils/responsive_helper.dart';

Widget build(BuildContext context) {
  return Container(
    // عرض الشاشة
    width: context.screenWidth,
    
    // طول الشاشة
    height: context.screenHeight,
    
    // 50% من عرض الشاشة
    width: context.wp(50),
    
    // 30% من طول الشاشة
    height: context.hp(30),
    
    // حجم خط متجاوب
    child: Text(
      'مرحباً',
      style: TextStyle(fontSize: context.sp(16)),
    ),
    
    // Padding متجاوب
    padding: EdgeInsets.all(
      context.padding(mobile: 16, tablet: 24, desktop: 32)
    ),
  );
}
```

### 2. التحقق من نوع الجهاز

```dart
Widget build(BuildContext context) {
  // التحقق السريع
  if (context.isMobile) {
    return MobileLayout();
  } else if (context.isTablet) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
  
  // أو باستخدام switch
  switch (context.deviceType) {
    case DeviceType.mobile:
      return MobileLayout();
    case DeviceType.tablet:
      return TabletLayout();
    case DeviceType.desktop:
      return DesktopLayout();
    case DeviceType.largeDesktop:
      return LargeDesktopLayout();
  }
}
```

### 3. ResponsiveLayout Widget

```dart
Widget build(BuildContext context) {
  return ResponsiveLayout(
    mobile: MobileWidget(),
    tablet: TabletWidget(),
    desktop: DesktopWidget(),
    largeDesktop: LargeDesktopWidget(), // اختياري
  );
}
```

### 4. ResponsiveBuilder Widget

```dart
Widget build(BuildContext context) {
  return ResponsiveBuilder(
    builder: (context, deviceType) {
      switch (deviceType) {
        case DeviceType.mobile:
          return Column(
            children: [
              // Mobile layout
            ],
          );
        case DeviceType.tablet:
          return Row(
            children: [
              // Tablet layout
            ],
          );
        default:
          return Row(
            children: [
              // Desktop layout
            ],
          );
      }
    },
  );
}
```

### 5. ResponsiveGrid Widget

```dart
Widget build(BuildContext context) {
  return ResponsiveGrid(
    mobileColumns: 2,     // عمودين للموبايل
    tabletColumns: 3,     // 3 أعمدة للتابلت
    desktopColumns: 4,    // 4 أعمدة للديسكتوب
    spacing: 16,
    runSpacing: 16,
    children: [
      Card1(),
      Card2(),
      Card3(),
      // ...
    ],
  );
}
```

---

## 📐 أمثلة عملية

### مثال 1: قائمة متجاوبة

```dart
class PharmaciesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الصيدليات',
          style: TextStyle(fontSize: context.sp(20)),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.padding()),
        child: ResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          children: pharmacies.map((pharmacy) {
            return PharmacyCard(pharmacy: pharmacy);
          }).toList(),
        ),
      ),
    );
  }
}
```

### مثال 2: بطاقة متجاوبة

```dart
class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.responsiveValue(
        mobile: context.screenWidth * 0.9,
        tablet: context.screenWidth * 0.45,
        desktop: context.screenWidth * 0.3,
      ),
      padding: EdgeInsets.all(
        context.padding(mobile: 12, tablet: 16, desktop: 20)
      ),
      child: Column(
        children: [
          // صورة متجاوبة
          Container(
            height: context.responsiveValue(
              mobile: 150.0,
              tablet: 200.0,
              desktop: 250.0,
            ),
            child: Image.network(pharmacy.imageUrl),
          ),
          
          SizedBox(height: context.hp(2)),
          
          // اسم الصيدلية
          Text(
            pharmacy.name,
            style: TextStyle(
              fontSize: context.sp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // الوصف
          Text(
            pharmacy.description,
            style: TextStyle(fontSize: context.sp(14)),
            maxLines: context.isMobile ? 2 : 3,
          ),
        ],
      ),
    );
  }
}
```

### مثال 3: Navigation Bar متجاوب

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar للديسكتوب فقط
          if (context.isDesktop)
            NavigationRail(
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home, size: context.iconSize()),
                  label: Text('الرئيسية'),
                ),
                // ...
              ],
            ),
          
          // المحتوى الرئيسي
          Expanded(
            child: Column(
              children: [
                // AppBar
                AppBar(
                  title: Text(
                    'الرئيسية',
                    style: TextStyle(fontSize: context.sp(20)),
                  ),
                  // Menu icon للموبايل فقط
                  leading: context.isMobile 
                    ? IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () {},
                      )
                    : null,
                ),
                
                // المحتوى
                Expanded(
                  child: ResponsiveLayout(
                    mobile: MobileContent(),
                    desktop: DesktopContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // BottomNavigationBar للموبايل والتابلت فقط
      bottomNavigationBar: !context.isDesktop
        ? BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              // ...
            ],
          )
        : null,
    );
  }
}
```

### مثال 4: Form متجاوب

```dart
class AddPharmacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          // عرض محدود للديسكتوب
          width: context.responsiveValue(
            mobile: context.screenWidth,
            tablet: context.screenWidth * 0.8,
            desktop: 600.0,
          ),
          padding: EdgeInsets.all(context.padding()),
          child: SingleChildScrollView(
            child: Form(
              child: Column(
                children: [
                  // حقول النموذج
                  ResponsiveBuilder(
                    builder: (context, deviceType) {
                      // Desktop: عمودين
                      if (deviceType == DeviceType.desktop) {
                        return Row(
                          children: [
                            Expanded(child: NameField()),
                            SizedBox(width: 16),
                            Expanded(child: PhoneField()),
                          ],
                        );
                      }
                      
                      // Mobile/Tablet: عمود واحد
                      return Column(
                        children: [
                          NameField(),
                          SizedBox(height: 16),
                          PhoneField(),
                        ],
                      );
                    },
                  ),
                  
                  // زر الإرسال
                  Container(
                    width: context.responsiveValue(
                      mobile: double.infinity,
                      tablet: context.wp(50),
                      desktop: context.wp(30),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        'حفظ',
                        style: TextStyle(fontSize: context.sp(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### مثال 5: GridView متجاوب

```dart
class DepartmentsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: context.padding(mobile: 12, desktop: 20),
        mainAxisSpacing: context.padding(mobile: 12, desktop: 20),
        childAspectRatio: context.responsiveValue(
          mobile: 1.0,
          tablet: 1.2,
          desktop: 1.4,
        ),
      ),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        return DepartmentCard(department: departments[index]);
      },
    );
  }
}
```

### مثال 6: Dialog متجاوب

```dart
void showPharmacyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(
        context.padding(mobile: 16, tablet: 24, desktop: 32)
      ),
      content: Container(
        width: context.responsiveValue(
          mobile: context.screenWidth * 0.9,
          tablet: context.screenWidth * 0.6,
          desktop: 500.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تفاصيل الصيدلية',
              style: TextStyle(fontSize: context.sp(20)),
            ),
            // ...
          ],
        ),
      ),
    ),
  );
}
```

---

## 🎨 أمثلة للتصميم

### Sidebar + Content (Desktop)

```dart
ResponsiveBuilder(
  builder: (context, deviceType) {
    if (deviceType == DeviceType.desktop) {
      return Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            child: NavigationDrawer(),
          ),
          // Content
          Expanded(child: MainContent()),
        ],
      );
    }
    
    // Mobile: Drawer + Content
    return Scaffold(
      drawer: NavigationDrawer(),
      body: MainContent(),
    );
  },
)
```

### Master-Detail Layout

```dart
ResponsiveLayout(
  mobile: ListScreen(), // القائمة فقط
  desktop: Row(
    children: [
      Expanded(
        flex: 1,
        child: ListScreen(), // القائمة على اليسار
      ),
      Expanded(
        flex: 2,
        child: DetailScreen(), // التفاصيل على اليمين
      ),
    ],
  ),
)
```

---

## ⚙️ إعدادات خاصة

### تخصيص نقاط التحول (Breakpoints)

إذا كنت تريد تغيير نقاط التحول، يمكنك تعديل `getDeviceType` في `responsive_helper.dart`:

```dart
static DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  
  // تخصيص النقاط
  if (width < 480) {
    return DeviceType.mobile;
  } else if (width < 768) {
    return DeviceType.tablet;
  } else if (width < 1024) {
    return DeviceType.desktop;
  } else {
    return DeviceType.largeDesktop;
  }
}
```

---

## 🧪 الاختبار

### اختبر على أحجام مختلفة

```bash
# iPhone SE
flutter run -d <device> --dart-define=DEVICE_WIDTH=375

# iPad
flutter run -d <device> --dart-define=DEVICE_WIDTH=768

# Desktop
flutter run -d windows
```

### في Chrome DevTools

1. اضغط F12
2. اضغط على أيقونة الجوال
3. جرب أحجام مختلفة

---

## ✅ Best Practices

### 1. استخدم Extension Methods

```dart
// ✅ Good
context.sp(16)
context.padding()

// ❌ Bad
ResponsiveHelper.sp(context, 16)
ResponsiveHelper.padding(context)
```

### 2. استخدم responsiveValue للقيم المختلفة

```dart
// ✅ Good
final columns = context.responsiveValue(
  mobile: 1,
  tablet: 2,
  desktop: 3,
);

// ❌ Bad
final columns = context.isMobile ? 1 : context.isTablet ? 2 : 3;
```

### 3. استخدم ResponsiveLayout للـ Widgets المختلفة

```dart
// ✅ Good
ResponsiveLayout(
  mobile: MobileWidget(),
  desktop: DesktopWidget(),
)

// ❌ Bad
context.isMobile ? MobileWidget() : DesktopWidget()
```

### 4. استخدم ResponsiveGrid للشبكات

```dart
// ✅ Good
ResponsiveGrid(
  mobileColumns: 2,
  tabletColumns: 3,
  children: items,
)

// ❌ Bad
GridView.count(
  crossAxisCount: context.isMobile ? 2 : 3,
  children: items,
)
```

---

## 📱 أمثلة جاهزة

### بطاقة منتج متجاوبة

```dart
class ProductCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(context.padding()),
        child: Column(
          children: [
            // صورة
            AspectRatio(
              aspectRatio: context.responsiveValue(
                mobile: 1.0,
                tablet: 1.2,
                desktop: 1.5,
              ),
              child: Image.network('...'),
            ),
            
            SizedBox(height: context.hp(1)),
            
            // العنوان
            Text(
              'منتج',
              style: TextStyle(
                fontSize: context.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // السعر
            Text(
              '100 جنيه',
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.green,
              ),
            ),
            
            // الزر
            SizedBox(
              width: context.responsiveValue(
                mobile: double.infinity,
                tablet: context.wp(30),
                desktop: context.wp(20),
              ),
              child: ElevatedButton(
                onPressed: () {},
                child: Text(
                  'اشترِ الآن',
                  style: TextStyle(fontSize: context.sp(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

**🎉 الآن التطبيق متجاوب بالكامل على جميع الأحجام!**
